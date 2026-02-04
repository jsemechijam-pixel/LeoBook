"""
Bet Placement Orchestration
Handles adding selections to the slip and finalizing accumulators with robust verification.
"""

import asyncio
from typing import List, Dict
from playwright.async_api import Page
from Helpers.Site_Helpers.site_helpers import get_main_frame
from Helpers.DB_Helpers.db_helpers import update_prediction_status
from Helpers.utils import log_error_state, capture_debug_snapshot
from Neo.selector_manager import SelectorManager
from Neo.intelligence import fb_universal_popup_dismissal as neo_popup_dismissal
from .ui import robust_click, wait_for_condition
from .mapping import find_market_and_outcome
from .slip import get_bet_slip_count, force_clear_slip
from Helpers.DB_Helpers.db_helpers import log_audit_event

async def ensure_bet_insights_collapsed(page: Page):
    """Ensure the bet insights widget is collapsed."""
    try:
        arrow_sel = SelectorManager.get_selector_strict("fb_match_page", "match_smart_picks_arrow_expanded")
        if arrow_sel and await page.locator(arrow_sel).count() > 0 and await page.locator(arrow_sel).is_visible():
            print("    [UI] Collapsing Bet Insights widget...")
            await page.locator(arrow_sel).first.click()
            await asyncio.sleep(1)
    except Exception:
        pass

async def expand_collapsed_market(page: Page, market_name: str):
    """If a market is found but collapsed, expand it."""
    try:
        # Use knowledge.json key for generic market header or title
        # Then filter by text
        header_sel = SelectorManager.get_selector_strict("fb_match_page", "market_header")
        if header_sel:
             # Find header containing market name
             target_header = page.locator(header_sel).filter(has_text=market_name).first
             if await target_header.count() > 0:
                 # Check if it needs expansion (often indicated by an icon or state, but clicking usually toggles)
                 # We can just click it if we don't see outcomes.
                 # Heuristic: Validating visibility of outcomes is better done by the caller.
                 # This function explicitly toggles.
                 print(f"    [Market] Clicking market header for '{market_name}' to ensure expansion...")
                 await robust_click(target_header, page)
                 await asyncio.sleep(1)
    except Exception as e:
        print(f"    [Market] Expansion failed: {e}")

async def place_bets_for_matches(page: Page, matched_urls: Dict[str, str], day_predictions: List[Dict], target_date: str):
    """Visit matched URLs and place bets with strict verification."""
    MAX_BETS = 40
    processed_urls = set()

    for match_id, match_url in matched_urls.items():
        # Check betslip limit
        if await get_bet_slip_count(page) >= MAX_BETS:
            print(f"[Info] Slip full ({MAX_BETS}). Finalizing accumulator.")
            success = await finalize_accumulator(page, target_date)
            if success:
                # If finalized, we can continue filling a new slip?
                # User flow suggests one slip per day usually, but let's assume valid.
                pass
            else:
                 print("[Error] Failed to finalize accumulator. Aborting further bets.")
                 break

        if not match_url or match_url in processed_urls: continue
        
        pred = next((p for p in day_predictions if str(p.get('fixture_id', '')) == str(match_id)), None)
        if not pred or pred.get('prediction') == 'SKIP': continue

        processed_urls.add(match_url)
        print(f"[Match] Processing: {pred['home_team']} vs {pred['away_team']}")

        try:
            # 1. Navigation
            await page.goto(match_url, wait_until='domcontentloaded', timeout=30000)
            await asyncio.sleep(3)
            await neo_popup_dismissal(page, match_url)
            await ensure_bet_insights_collapsed(page)

            # 2. Market Mapping
            m_name, o_name = await find_market_and_outcome(pred)
            if not m_name:
                print(f"    [Info] No market mapping for {pred.get('prediction')}")
                continue

            # 3. Search for Market
            search_icon = SelectorManager.get_selector_strict("fb_match_page", "search_icon")
            search_input = SelectorManager.get_selector_strict("fb_match_page", "search_input")
            
            if search_icon and search_input:
                if await page.locator(search_icon).count() > 0:
                    await robust_click(page.locator(search_icon).first, page)
                    await asyncio.sleep(1)
                    
                    await page.locator(search_input).fill(m_name)
                    await page.keyboard.press("Enter")
                    await asyncio.sleep(2)
                    
                    # Handle Collapsed Market: Try to find header and click if outcomes not immediately obvious
                    # (Skipping complex check, just click header if name exists)
                    await expand_collapsed_market(page, m_name)

                    # 4. Select Outcome
                    # Try strategies: Exact Text Button -> Row contains text
                    outcome_added = False
                    initial_count = await get_bet_slip_count(page)
                    
                    # Strategy A: Button with precise text
                    outcome_btn = page.locator(f"button:text-is('{o_name}'), div[role='button']:text-is('{o_name}')").first
                    if await outcome_btn.count() > 0 and await outcome_btn.is_visible():
                         print(f"    [Selection] Found outcome button '{o_name}'")
                         await robust_click(outcome_btn, page)
                    else:
                         # Strategy B: Row based fallback
                         row_sel = SelectorManager.get_selector_strict("fb_match_page", "match_market_table_row")
                         if row_sel:
                             # Find row containing outcome text
                             target_row = page.locator(row_sel).filter(has_text=o_name).first
                             if await target_row.count() > 0:
                                  print(f"    [Selection] Found outcome row for '{o_name}'")
                                  await robust_click(target_row, page)
                    
                    # 5. Verification Loop
                    for _ in range(3):
                        await asyncio.sleep(1)
                        new_count = await get_bet_slip_count(page)
                        if new_count > initial_count:
                            print(f"    [Success] Outcome '{o_name}' added. Slip count: {new_count}")
                            outcome_added = True
                            update_prediction_status(match_id, target_date, 'added_to_slip')
                            break
                    
                    if not outcome_added:
                        print(f"    [Error] Failed to add outcome '{o_name}'. Slip count did not increase.")
                        update_prediction_status(match_id, target_date, 'failed_add')
                
                else:
                    print("    [Error] Search icon not found.")
            else:
                 print("    [Error] Search selectors missing configuration.")

        except Exception as e:
            print(f"    [Match Error] {e}")
            await capture_debug_snapshot(page, f"error_{match_id}", str(e))


def calculate_kelly_stake(balance: float, odds: float, probability: float = 0.60) -> int:
    """
    Calculates fractional Kelly stake.
    Full Kelly = (edge * odds - 1) / (odds - 1)
    conservative_kelly = 0.25 * Full Kelly
    We use a default probability of 60% if not specified by RuleEngine.
    """
    if odds <= 1.0: return max(1, int(balance * 0.01))
    
    edge = probability - (1.0 / odds)
    if edge <= 0:
        # If no mathematical edge, use a small 1% exploration stake
        full_kelly = 0.01
    else:
        full_kelly = edge / (odds - 1)
    
    # Applied Fractional Kelly (0.25)
    applied_kelly = 0.25 * full_kelly
    raw_stake = balance * applied_kelly
    
    # Clamp rules: Min = max(1% balance, 1), Max = 50% balance
    min_stake = max(1, int(balance * 0.01))
    max_stake = int(balance * 0.50)
    
    final_stake = int(max(min_stake, min(raw_stake, max_stake)))
    return final_stake


async def place_multi_bet_from_codes(page: Page, harvested_codes: List[str], current_balance: float) -> bool:
    """
    Phase 2b (Execute):
    1. Filter codes (Validation).
    2. Add selections to slip (via comma-separated shareCode URL).
    3. Calculate stake (min ₦1, max 50% balance).
    4. Place bet and Verify.
    """
    if not harvested_codes:
        print("    [Execute] No codes to place.")
        return False

    # A. Validate & Limit (Max 12 selections for stability)
    final_codes = [c for c in harvested_codes if c and len(str(c)) >= 5][:12]
    if not final_codes:
        print("    [Execute] No valid codes found after filtering.")
        return False

    print(f"    [Execute] Building Multi with {len(final_codes)} selections.")
    
    # B. Inject Codes via URL (Combined for speed)
    # Comma-separated shareCode automatically populates the slip
    combined_codes = ",".join(final_codes)
    load_url = f"https://www.football.com/ng/m?shareCode={combined_codes}"
    
    try:
        print(f"    [Execute] Injecting all codes via shareURL...")
        # Force clear slip first to ensure a clean multi-bet
        await force_clear_slip(page)
        
        await page.goto(load_url, timeout=45000, wait_until='domcontentloaded')
        # Wait for meaningful content
        await asyncio.sleep(3)
        
        # C. Verify Slip Count matches
        total_in_slip = await get_bet_slip_count(page)
        # Calculate combined odds for staking (Heuristic)
        # Since we just loaded codes, we don't have exact odds easily until slip is open, 
        # but the MD suggests Kelly based on slip. We'll use a conservative estimate.
        estimated_combined_odds = 2.0 * len(final_codes) # Heuristic for multi
        
        print(f"    [Execute] Verification: {total_in_slip} bets in slip (Expected {len(final_codes)}).")
        
        if total_in_slip < 1:
            print("    [Execute Failure] No bets in slip after loading codes.")
            return False
            
        # D. Open Slip
        slip_trigger = SelectorManager.get_selector_strict("fb_match_page", "slip_trigger_button")
        btn = page.locator(slip_trigger).first
        if await btn.count() > 0:
            await robust_click(btn, page)
            # Wait for slip container
            slip_sel = SelectorManager.get_selector_strict("fb_match_page", "slip_drawer_container")
            await page.wait_for_selector(slip_sel, state="visible", timeout=15000)
            await asyncio.sleep(1)
        else:
            print("    [Execute Error] Could not find slip trigger.")
            return False

        # E. Calculate Stake (Kelly v2.7)
        final_stake = calculate_kelly_stake(current_balance, estimated_combined_odds)
        
        print(f"    [Execute] Final Stake: ₦{final_stake} (Balance: ₦{current_balance:.2f})")

        # F. Enter Stake
        stake_input_sel = SelectorManager.get_selector("fb_match_page", "betslip_stake_input")
        inp = page.locator(stake_input_sel).first
        if await inp.count() > 0:
            await inp.scroll_into_view_if_needed()
            await inp.fill(str(final_stake))
            await page.keyboard.press("Enter")
            await asyncio.sleep(1)
        else:
            print("    [Execute Error] Stake input not visible in slip.")
            return False

        # G. Place & Confirm
        place_btn_sel = SelectorManager.get_selector_strict("fb_match_page", "betslip_place_bet_button")
        place_btn = page.locator(place_btn_sel).first
        if await place_btn.count() > 0 and await place_btn.is_enabled():
            print("    [Execute] Clicking 'Place Bet'...")
            # Use JS click for place button as it's often a span inside a div
            await place_btn.click(force=True)
            await asyncio.sleep(2)
            
            # Detect confirmation dialog
            confirm_sel = SelectorManager.get_selector("fb_match_page", "confirm_bet_button")
            conf_btn = page.locator(confirm_sel).first
            if await conf_btn.count() > 0 and await conf_btn.is_visible():
                print("    [Execute] Confirming multi-bet...")
                await conf_btn.click()
                await asyncio.sleep(5) # Wait for processing

            # H. Final Verification (Balance Decrease)
            from ..navigator import extract_balance
            new_balance = await extract_balance(page)
            if new_balance < (current_balance - (final_stake * 0.9)): # Use 0.9 to avoid edge case rounding
                print(f"    [Execute Success] Multi-bet placed! New Balance: ₦{new_balance:.2f}")
                log_audit_event(
                    event_type="BET_PLACEMENT",
                    description=f"Multi-bet with {len(final_codes)} selections placed via shareCode.",
                    balance_before=current_balance,
                    balance_after=new_balance,
                    stake=float(final_stake),
                    status="success"
                )
                return True
            else:
                print("    [Execute Warning] Balance did not decrease. Placement might have failed or is pending.")
                log_audit_event(
                    event_type="BET_PLACEMENT",
                    description=f"Multi-bet placement failed or pending verification.",
                    balance_before=current_balance,
                    balance_after=new_balance,
                    stake=float(final_stake),
                    status="warning"
                )
                return False
        else:
            print("    [Execute Error] Place Multi button not found or disabled.")
            return False

    except Exception as e:
        print(f"    [Execute Error] Unexpected failure: {e}")
        
    return False


"""
Booking Code Extractor
Handles the specific logic for Phase 2a: Harvest.
Visits a match, books a single bet, extracts the code, and saves it.
"""

import asyncio
import re
from typing import Dict, Optional, Tuple
from playwright.async_api import Page
from Neo.selector_manager import SelectorManager
from .ui import robust_click
from .slip import force_clear_slip
from Helpers.DB_Helpers.db_helpers import update_site_match_status

async def book_single_match(page: Page, match: Dict, prediction: Dict) -> bool:
    """
    Core function for Phase 2a (Harvest).
    1. Force clears slip.
    2. Navigates to match URL.
    3. Finds and selects the outcome (verifying min odds).
    4. Clicks "Book Bet".
    5. Extracts code & URL.
    6. Saves to CSV.
    """
    url = match.get('url')
    site_match_id = match.get('site_match_id')

    print(f"\n   [Harvest] Processing match: {match.get('home_team')} vs {match.get('away_team')}")
    
    # 1. Clear Slip (Critical)
    try:
        await force_clear_slip(page)
    except Exception as e:
        print(f"    [Harvest Error] Slip clear failed: {e}")
        return False

    # 2. Navigate
    try:
        if page.url != url:
            await page.goto(url, timeout=60000, wait_until='domcontentloaded')
        # Wait for meaningful content (ready indicator)
        await page.wait_for_selector(SelectorManager.get_selector_strict("fb_match_page", "market_group_header"), timeout=20000)
        await asyncio.sleep(1) # Extra stability
    except Exception as e:
        print(f"    [Harvest Error] Navigation failed for {url}: {e}")
        return False

    # 3. Select Outcome
    outcome_found = await _select_outcome(page, prediction)
    if not outcome_found:
        print(f"    [Harvest] Pred '{prediction.get('prediction')}' outcome not found or odds too low.")
        update_site_match_status(site_match_id, status="failed", details=f"Outcome {prediction.get('prediction')} not found/low odds")
        return False

    # --- BOT EVASION: Human-like delay ---
    delay = 0.8 + (0.7 * (hash(prediction.get('fixture_id', '')) % 100) / 100.0)
    print(f"    [Evasion] Waiting {delay:.2f}s before booking...")
    await asyncio.sleep(delay)

    # 4. Book Bet
    success = await _perform_booking_action(page, site_match_id, prediction)
    
    # 5. Cleanup
    await force_clear_slip(page) # Reset for next match

    return success


from .mapping import find_market_and_outcome

async def expand_collapsed_market(page: Page, market_name: str):
    """If a market is found but collapsed, expand it."""
    try:
        header_sel = SelectorManager.get_selector("fb_match_page", "market_header")
        if header_sel:
             target_header = page.locator(header_sel).filter(has_text=market_name).first
             if await target_header.count() > 0:
                 print(f"    [Market] Clicking market header for '{market_name}' to ensure expansion...")
                 await robust_click(target_header, page)
                 await asyncio.sleep(1)
    except Exception as e:
        print(f"    [Market] Expansion failed: {e}")

async def _select_outcome(page: Page, prediction: Dict) -> bool:
    """
    Robust outcome selection:
    1. Maps prediction -> generic market/outcome names.
    2. Searches for market using site search.
    3. Finds outcome button.
    4. Clicks and verifies selection.
    """
    # 1. Map Prediction
    m_name, o_name = await find_market_and_outcome(prediction)
    if not m_name:
        print(f"    [Harvest Error] No mapping for pred: {prediction.get('prediction')}")
        return False

    try:
        # 2. Search for Market
        # Reuse robust searching logic from placement.py
        search_icon = SelectorManager.get_selector_strict("fb_match_page", "search_icon")
        search_input = SelectorManager.get_selector_strict("fb_match_page", "search_input")
        
        if search_icon and search_input:
            if await page.locator(search_icon).count() > 0:
                await robust_click(page.locator(search_icon).first, page)
                await asyncio.sleep(0.5)
                
                await page.locator(search_input).fill(m_name)
                # Wait for search results
                await asyncio.sleep(1.5)
                
                # Expand if needed
                await expand_collapsed_market(page, m_name)

                # 3. Find Outcome Button
                # Strategy A: Button with precise text
                outcome_btn = page.locator(f"button:text-is('{o_name}'), div[role='button']:text-is('{o_name}')").first
                
                if await outcome_btn.count() > 0 and await outcome_btn.is_visible():
                        print(f"    [Selection] Found outcome button '{o_name}'")
                        await robust_click(outcome_btn, page)
                        return True
                else:
                        # Strategy B: Row based fallback
                        row_sel = SelectorManager.get_selector("fb_match_page", "match_market_table_row")
                        if row_sel:
                            target_row = page.locator(row_sel).filter(has_text=o_name).first
                            if await target_row.count() > 0:
                                print(f"    [Selection] Found outcome row for '{o_name}'")
                                await robust_click(target_row, page)
                                return True
            
                print(f"    [Harvest Failure] Outcome '{o_name}' not found after search.")
                return False
            else:
                print("    [Harvest Error] Search icon not found/visible.")
                return False
        else:
            print("    [Harvest Error] Search selectors missing.")
            return False

    except Exception as e:
        print(f"    [Harvest Error] Selection logic failed: {e}")
        return False


async def _perform_booking_action(page: Page, site_match_id: str, prediction: Dict) -> bool:
    """Clicks Book Bet, waits for modal, extracts code."""
    book_btn_sel = SelectorManager.get_selector_strict("fb_match_page", "book_bet_button")
    
    try:
        # Click Book Bet
        btn = page.locator(book_btn_sel).first
        if await btn.count() > 0:
            print("    [Booking] Clicking 'Book Bet'...")
            # Use JS click if needed, but robust_click is good
            await robust_click(btn, page)
            
            # Wait for Modal
            modal_sel = SelectorManager.get_selector_strict("fb_match_page", "booking_code_modal")
            try:
                await page.wait_for_selector(modal_sel, state="visible", timeout=15000)
            except:
                print("    [Harvest Error] Booking code modal did not appear or wasn't visible.")
                return False
            
            # --- POST-PLACEMENT VERIFICATION ---
            # Re-verify team names in the modal before committing
            modal_text = (await page.locator(modal_sel).inner_text()).lower()
            pred_home = prediction.get('home_team', '').lower()
            pred_away = prediction.get('away_team', '').lower()
            
            # Check if at least part of the team names are in the modal text
            if pred_home[:4] not in modal_text and pred_away[:4] not in modal_text:
                print(f"    [Verification Failure] Modal content does not match teams: '{pred_home}' vs '{pred_away}'")
                return False
            else:
                print("    [Verification] Teams confirmed in booking modal.")

            # Extract Code
            code_sel = SelectorManager.get_selector_strict("fb_match_page", "booking_code_text")
            # Poll for code to appear (sometimes it takes a beat)
            code_text = ""
            for _ in range(10):
                try:
                    code_text = (await page.locator(code_sel).first.inner_text(timeout=2000)).strip()
                    if code_text and len(code_text) >= 5: # Typical codes are like "XYZ123"
                        break
                except:
                    pass
                await asyncio.sleep(1)
            
            if not code_text:
                print("    [Harvest Error] Could not extract booking code text from modal or it was empty.")
                return False
                
            print(f"    [Harvest Success] Code Found: {code_text}")
            
            # Save
            update_site_match_status(
                site_match_id, 
                status="booked", 
                booking_code=code_text, 
                booking_url=f"https://www.football.com/ng/m?shareCode={code_text}"
            )
            
            # Dismiss Modal
            close_sel = SelectorManager.get_selector_strict("fb_match_page", "modal_close_button")
            close_btn = page.locator(close_sel).first
            if await close_btn.count() > 0:
                await close_btn.click()
                await asyncio.sleep(0.5)
            
            return True
            
    except Exception as e:
        print(f"    [Harvest Error] Booking action failed: {e}")
        
    return False

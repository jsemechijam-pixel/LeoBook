"""
Single Match Booking Module (Phase 2a: Harvest)
Responsible for booking a single match to extract a booking code.
Focuses on reliability, retries, and clean state.
"""

import asyncio
import re
from typing import Dict, Tuple, Optional
from playwright.async_api import Page
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type, before_sleep_log
import logging

from Helpers.Site_Helpers.site_helpers import get_main_frame
from Helpers.utils import log_error_state
from Neo.selector_manager import SelectorManager
from Neo.intelligence import fb_universal_popup_dismissal as neo_popup_dismissal
from .ui import robust_click
from .mapping import find_market_and_outcome
from .slip import force_clear_slip, get_bet_slip_count


# --- RETRY CONFIGURATION ---
def log_retry_attempt(retry_state):
    print(f"      [Booking Retry] Attempt {retry_state.attempt_number} failed. Retrying...")

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1.5, min=3, max=15),
    retry=retry_if_exception_type(Exception),
    before_sleep=log_retry_attempt
)
async def book_single_match(page: Page, match_data: Dict) -> Tuple[Optional[str], Optional[str]]:
    """
    Orchestrates the booking of a single match.
    Returns: (booking_code, booking_url) or (None, None)
    """
    booking_code = None
    booking_url = None
    
    match_label = f"{match_data.get('home_team')} vs {match_data.get('away_team')}"
    match_url = match_data.get('url')
    
    if not match_url:
        print(f"    [Skip] No URL for {match_label}")
        return None, None

    print(f"\n   [Harvest] Booking: {match_label}")

    try:
        # Pre-condition: Clean slip
        await force_clear_slip(page)

        # 1. Navigation
        await page.goto(match_url, wait_until='domcontentloaded', timeout=45000)
        await asyncio.sleep(2)
        await neo_popup_dismissal(page, match_url)
        
        # 2. Market Mapping
        m_name, o_name = await find_market_and_outcome(match_data)
        if not m_name:
            print(f"    [Skip] Mapping failed for {match_label}")
            return None, None

        # 3. Search & Select
        search_icon = SelectorManager.get_selector_strict("fb_match_page", "search_icon")
        search_input = SelectorManager.get_selector_strict("fb_match_page", "search_input")
            
        if search_icon and search_input and await page.locator(search_icon).first.is_visible():
             await robust_click(page.locator(search_icon).first, page)
             await page.locator(search_input).first.fill(m_name)
             await page.keyboard.press("Enter")
             await asyncio.sleep(1.5)

        # Heuristic for outcome button
        outcome_found = False
        initial_count = await get_bet_slip_count(page)
        
        # Try finding button by exact text or within market container
        potential_selectors = [
            f"button:has-text('{o_name}')",
            f"div[role='button']:has-text('{o_name}')",
            f"span:text-is('{o_name}')",
            f".m-outcome:has-text('{o_name}')"
        ]
        
        for sel in potential_selectors:
            btn = page.locator(sel).first
            if await btn.count() > 0 and await btn.is_visible():
                print(f"    [Selection] Attempting click on '{o_name}' via '{sel}'")
                if await robust_click(btn, page):
                    await asyncio.sleep(1.5)
                    if await get_bet_slip_count(page) > initial_count:
                        outcome_found = True
                        break
        
        if not outcome_found:
             print(f"    [Fail] Outcome '{o_name}' not added to slip.")
             return None, None
            
        # 4. Book Bet
        book_btn_sel = SelectorManager.get_selector_strict("fb_match_page", "book_bet_button") or "button:has-text('Book a bet')" 
        book_btn = page.locator(book_btn_sel).first
        
        if await book_btn.count() > 0 and await book_btn.is_visible():
            await robust_click(book_btn, page)
            print("    [Action] Clicked 'Book a bet'")
            
            # 5. Extract Code
            code_display_sel = SelectorManager.get_selector_strict("fb_match_page", "booking_code_display") or "div.booking-code-text"
            try:
                # Use a combined selector for common code displays
                await page.wait_for_selector(f"{code_display_sel}, .m-booking-code", timeout=12000)
                code_el = page.locator(f"{code_display_sel}, .m-booking-code").first
                booking_code = (await code_el.inner_text()).strip()
                print(f"    [Success] Booking Code: {booking_code}")
                
                # Cleanup: Dismiss modal
                await page.keyboard.press("Escape")
                close_btn = page.locator(".m-dialog-close, .m-modal-close").first
                if await close_btn.count() > 0:
                    await close_btn.click()
            except Exception as e:
                print(f"    [Warning] Code extraction error: {e}")
        else:
            print("    [Error] 'Book a bet' button not found.")
            
        # Post-condition: Clean slip
        await force_clear_slip(page)
        
        return booking_code, None 

    except Exception as e:
        print(f"    [Booking Error] {match_label}: {e}")
        await log_error_state(page, f"harvest_fail_{match_label.replace(' ', '_')}", e)
        # Attempt emergency clear
        try: await force_clear_slip(page)
        except: pass
        raise e 

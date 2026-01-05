#!/usr/bin/env python3
"""
Test Script for HTML-Based State Discovery
Demonstrates the updated Smart Awareness framework using HTML analysis instead of screenshots.
"""

import asyncio
import json
from playwright.async_api import async_playwright

# Mock Leo AI response for testing (replace with actual API call)
async def mock_leo_response(prompt_text):
    """Mock Leo AI response for testing purposes"""
    if "STATE_DISCOVERY_PROMPT" in prompt_text:
        # Simulate state discovery response
        return type('MockResponse', (), {
            'text': json.dumps({
                "state": "login_page",
                "is_modal": False,
                "milestone_found": "Login form elements detected",
                "primary_exit_selector": "button[type='submit']"
            })
        })()
    elif "RECOVERY_PROMPT" in prompt_text:
        # Simulate recovery response
        return type('MockResponse', (), {
            'text': json.dumps({
                "selector": "button[data-dismiss='modal']"
            })
        })()
    return None

async def test_html_discovery():
    """Test the HTML-based state discovery functionality"""
    print("Testing HTML-Based Smart Awareness Framework")
    print("=" * 60)

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        page = await context.new_page()

        try:
            # Navigate to a test page (using a simple HTML page for demonstration)
            test_html = """
            <!DOCTYPE html>
            <html>
            <head><title>Test Login Page</title></head>
            <body>
                <h1>Welcome to Football.com</h1>
                <div class="login-form">
                    <h2>Please Log In</h2>
                    <input type="tel" placeholder="Phone Number" />
                    <input type="password" placeholder="Password" />
                    <button type="submit">Login</button>
                </div>
                <div class="modal overlay" style="display: block;">
                    <div class="modal-content">
                        <p>Accept our terms and conditions?</p>
                        <button data-dismiss="modal">Accept</button>
                        <button>Decline</button>
                    </div>
                </div>
            </body>
            </html>
            """

            await page.set_content(test_html)

            # Import the updated functions
            from Neo.page_analyzer import PageAnalyzer
            from Neo.recovery import attempt_visual_recovery

            print("\n1. Testing State Discovery (HTML-based)")
            print("-" * 40)

            # Test state discovery
            state_info = await PageAnalyzer.discover_state_via_ai(page)
            print(f"Discovered State: {state_info}")

            print("\n2. Testing Recovery Mechanism (HTML-based)")
            print("-" * 40)

            # Test recovery
            recovery_success = await attempt_visual_recovery(page, "test_context")
            print(f"Recovery Action Taken: {recovery_success}")

            print("\nSUCCESS: HTML-Based Analysis Complete!")
            print("Benefits of HTML approach:")
            print("   * No image data = smaller context windows")
            print("   * Faster processing (no screenshot capture)")
            print("   * More reliable text extraction")
            print("   * Better for automation (structured data)")

        except Exception as e:
            print(f"Test failed: {e}")
        finally:
            await browser.close()

if __name__ == "__main__":
    asyncio.run(test_html_discovery())

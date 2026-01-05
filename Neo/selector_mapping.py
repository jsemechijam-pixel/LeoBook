"""
Selector Mapping Module
Handles AI-powered mapping of visual UI elements to CSS selectors.
"""

import json
import re
import asyncio
from typing import Dict, Optional

from Helpers.Neo_Helpers.Managers.api_key_manager import leo_api_call_with_rotation
from .utils import clean_json_response
from .prompts import get_keys_for_context, BASE_MAPPING_INSTRUCTIONS


async def map_visuals_to_selectors(
    ui_visual_context: str, html_content: str, context_key: Optional[str] = None
) -> Optional[Dict[str, str]]:
    """Map visual UI elements to CSS selectors using Leo AI with dynamic context-aware keys"""

    # 1. Determine Context and Keys
    # Note: focal_context is passed from analyzer as 'info' or 'context_key'
    ctx = context_key or "shared"
    target_keys = get_keys_for_context(ctx)
    keys_str = json.dumps(target_keys, indent=2)

    # 2. Build Prompt
    prompt = f"{BASE_MAPPING_INSTRUCTIONS}\n\n### MANDATORY KEYS FOR THIS CONTEXT:\n{keys_str}"
    
    prompt_tail = f"""
    ### INPUT
    --- VISUAL CONTEXT ---
    {ui_visual_context}
    --- CLEANED HTML SOURCE ---
    {html_content}
    
    Return ONLY the JSON mapping. No explanations. No markdown.
    """

    full_prompt = prompt + prompt_tail

    try:
        # Note: mapping uses Leo AI for its reasoning on DOM structures
        response = await leo_api_call_with_rotation(
            full_prompt,  # type: ignore
            generation_config={"response_mime_type": "application/json"}  # type: ignore
        )

        # Extract text from response
        response_text = None
        try:
            if response and hasattr(response, 'text') and response.text:
                response_text = response.text
        except Exception:
            pass

        if not response_text and response and hasattr(response, 'candidates') and response.candidates:
            try:
                if len(response.candidates) > 0 and response.candidates[0].content.parts:
                    response_text = response.candidates[0].content.parts[0].text
            except (IndexError, AttributeError):
                print(f"    [MAPPING ERROR] Could not extract text from response candidates")
                return None

        if not response_text:
            print(f"    [MAPPING ERROR] Invalid response format")
            return None

        cleaned_json = clean_json_response(response_text)

        try:
            return json.loads(cleaned_json)
        except json.JSONDecodeError as json_error:
            print(f"    [MAPPING ERROR] JSON parsing failed: {json_error}")
            return None

    except Exception as e:
        print(f"    [MAPPING ERROR] Failed to map visuals to selectors: {e}")
        return None

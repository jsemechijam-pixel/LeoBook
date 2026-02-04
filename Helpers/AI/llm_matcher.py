import requests
import json
import os
import asyncio
from typing import Optional, Dict

class SemanticMatcher:
    def __init__(self, model: str = 'qwen3-vl:2b-custom'):
        """
        Initialize the SemanticMatcher for local LLM server (OpenAI-compatible endpoint).
        """
        self.model = model
        self.api_url = os.getenv("LLM_API_URL", "http://127.0.0.1:8080/v1/chat/completions")
        self.timeout = int(os.getenv("LLM_TIMEOUT", "15"))  # Reduced from 60s to 15s for better performance
        self.cache = {}  # Add caching to avoid repeated LLM calls

    async def is_match(self, desc1: str, desc2: str, league: Optional[str] = None) -> Optional[Dict]:
        """
        Determines if two match descriptions refer to the same football fixture.
        Returns a dict with 'is_match' (bool) and 'confidence' (int 0-100).
        """
        cache_key = f"{desc1}|{desc2}|{league or ''}"
        if cache_key in self.cache:
            return self.cache[cache_key]

        context = ""
        if league:
            context = f"Both matches are in the league/competition: {league}. "

        prompt = (
            f"You are a precise sports betting matcher. Analyze if these two match descriptions refer to the EXACT SAME fixture.\n\n"
            f"Prediction: {desc1}\n"
            f"Site Candidate: {desc2}\n"
            f"{context}\n"
            f"Rules:\n"
            f"1. Ignore minor name variations (e.g. 'Fatih Karagumruk' = 'Karagumruk').\n"
            f"2. Ignore 'Istanbul' vs no 'Istanbul'.\n"
            f"3. Reject if league, date, or home/away order differs meaningfully.\n"
            f"4. Be strict about team identities.\n\n"
            f"Response MUST be valid JSON in this format: {{\"is_match\": bool, \"confidence\": int, \"reason\": string}}"
        )

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": "You are a precise sports betting analyzer. You only speak JSON."},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.0,
            "max_tokens": 150,
            "response_format": {"type": "json_object"} # If supported by server
        }

        try:
            def _do_request():
                return requests.post(
                    self.api_url,
                    json=payload,
                    timeout=self.timeout
                )

            response = await asyncio.to_thread(_do_request)
            response.raise_for_status()

            data = response.json()
            content = data['choices'][0]['message']['content'].strip()
            
            # Robust JSON parsing
            try:
                # Find JSON block if model talked outside it
                if "{" in content:
                    content = content[content.find("{"):content.rfind("}")+1]
                
                result = json.loads(content)
                
                # Normalize types
                if 'is_match' in result:
                    result['is_match'] = bool(result['is_match'])
                if 'confidence' in result:
                    result['confidence'] = int(result['confidence'])
                
                self.cache[cache_key] = result
                return result
            except (json.JSONDecodeError, ValueError, KeyError) as parse_error:
                print(f"  [LLM Matcher] JSON Parse Error: {parse_error}. Content: {content[:100]}...")
                # Fallback to simple yes/no detection if JSON fails
                content_lower = content.lower()
                simple_result = {
                    "is_match": "true" in content_lower or "yes" in content_lower,
                    "confidence": 70, # Lower confidence for malformed response
                    "reason": "fallback_parsing"
                }
                self.cache[cache_key] = simple_result
                return simple_result

        except Exception as e:
            print(f"  [LLM Matcher Error] {e}")
            return None

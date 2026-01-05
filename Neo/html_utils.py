"""
HTML Utilities Module
Handles HTML content cleaning and processing for visual analysis.
"""

import re


def clean_html_content(html_content: str) -> str:
    """Clean HTML content to reduce token usage"""
    import re

    # Remove script and style tags
    html_content = re.sub(
        r"<script.*?</script>", "", html_content, flags=re.DOTALL | re.IGNORECASE
    )
    html_content = re.sub(
        r"<style.*?</style>", "", html_content, flags=re.DOTALL | re.IGNORECASE
    )

    # Truncate aggressively to fit within 8192 context (including instructions)
    return html_content[:5000]

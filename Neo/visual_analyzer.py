"""
Visual Analyzer Module
Handles screenshot analysis and visual UI processing using Local Leo AI.
Orchestrates sub-modules for visual analysis, selector mapping, and recovery.
"""

from typing import Dict, Any, List, Optional
from pathlib import Path

from Helpers.Neo_Helpers.Managers.db_manager import knowledge_db, save_knowledge
from Helpers.Site_Helpers.page_logger import log_page_html
from Helpers.utils import LOG_DIR

# Import sub-modules
from .html_utils import clean_html_content
from .visual_analysis import get_visual_ui_analysis
from .selector_mapping import map_visuals_to_selectors
from .selector_utils import simplify_selectors
from .recovery import attempt_visual_recovery


class VisualAnalyzer:
    """Handles visual analysis of web pages by orchestrating sub-modules"""

    @staticmethod
    async def analyze_page_and_update_selectors(
        page,
        context_key: str,
        force_refresh: bool = False,
        info: Optional[str] = None,
    ) -> None:
        """
        The "memory creator" for Leo. This function is the core of the auto-healing mechanism.
        Orchestrates discovery and mapping of UI elements to CSS selectors.
        """
        # --- INTELLIGENT SKIP LOGIC ---
        if not force_refresh and context_key in knowledge_db and knowledge_db[context_key]:
            print(f"    [AI INTEL] Selectors found for '{context_key}'. Skipping AI analysis.")
            return

        print(
            f"    [AI INTEL] Starting Full Discovery for context: '{context_key}' (Force: {force_refresh})..."
        )

        print(f"    [AI INTEL] Capturing page state for '{context_key}'...")
        await log_page_html(page, context_key)

        # Step 1: Visual Inventory (Optional/Fallback)
        # For now, we often use HTML-only or semi-visual.
        # But we keep the hook for full visual analysis.
        ui_visual_context = "NO VISUAL CONTEXT AVAILABLE. ANALYZE HTML DOM ONLY."
        
        # If we wanted to enable visual:
        # ui_visual_context = await get_visual_ui_analysis(page, context_key) or ui_visual_context

        # Step 2: Load HTML
        PAGE_LOG_DIR = LOG_DIR / "Page"
        files = list(PAGE_LOG_DIR.glob(f"*{context_key}.html"))
        if not files:
            print(f"    [AI INTEL ERROR] No HTML file found for context: {context_key}")
            return

        html_file = max(files, key=lambda x: x.stat().st_mtime)
        print(f"    [AI INTEL] Using logged HTML: {html_file.name}")

        try:
            with open(html_file, "r", encoding="utf-8") as f:
                html_content = f.read()
        except Exception as e:
            print(f"    [AI INTEL ERROR] Failed to load HTML: {e}")
            return

        # Clean HTML to save tokens
        html_content = clean_html_content(html_content)

        # Step 3: Map Visuals/Intent to HTML Selectors
        print("    [AI INTEL] Mapping UI Elements to HTML Selectors...")
        new_selectors = await map_visuals_to_selectors(
            ui_visual_context, html_content, context_key
        )

        if new_selectors:
            # Simplify complex selectors before saving
            simplified_selectors = simplify_selectors(new_selectors, html_content)
            
            if context_key not in knowledge_db:
                knowledge_db[context_key] = {}
            
            knowledge_db[context_key].update(simplified_selectors)
            save_knowledge() # Persistent STORAGE
            
            print(f"    [AI INTEL] Successfully mapped {len(simplified_selectors)} elements.")
        else:
            print(f"    [AI INTEL ERROR] Failed to generate selectors map.")

    # Re-export key functions as static methods for backward compatibility if needed
    @staticmethod
    async def get_visual_ui_analysis(page, context_key: str) -> Optional[str]:
        return await get_visual_ui_analysis(page, context_key)

    @staticmethod
    def clean_html_content(html_content: str) -> str:
        return clean_html_content(html_content)

    @staticmethod
    async def map_visuals_to_selectors(
        ui_visual_context: str, html_content: str, focus: Optional[str] = None
    ) -> Optional[Dict[str, str]]:
        return await map_visuals_to_selectors(ui_visual_context, html_content, focus)

    @staticmethod
    def simplify_selectors(selectors: Dict[str, str], html_content: str) -> Dict[str, str]:
        return simplify_selectors(selectors, html_content)

    @staticmethod
    async def attempt_visual_recovery(page, context_name: str) -> bool:
        return await attempt_visual_recovery(page, context_name)

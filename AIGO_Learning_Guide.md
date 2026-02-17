# AIGO: Autonomous Intelligent Guardian & Observer (v5.0)

AIGO is the "Self-Healing Surgeon" of the LeoBook automation engine. It is designed to ensure that the system never stops, even if the target website (Flashscore, Football.com) changes its UI, adds popups, or renames its internal CSS classes.

---

## 1. The Core Philosophy: "Fail-Proof Automation"
Traditional bots break when a button's ID changes. AIGO does not. Instead of relying on static code, AIGO uses **Visual-Structural Reasoning**. If it can't find a button by its name (`#bet-button`), it "looks" at the page, identifies a "button-like object" near the "Stake" field, and tries to click that instead.

---

## 2. The Execution Pipeline (The 4 Phases)

When the `InteractionEngine` is asked to do something (e.g., "Click the Home Team Win button"), it follows this AIGO-managed loop:

### Phase 1: Memory & Reinforcement Learning
- **The Library**: `MemoryManager.py`
- **Logic**: It first checks if it has a **"Recent Success Pattern"**. If a specific selector worked in the last 24 hours, it tries it immediately. This makes the bot fast during stable UI periods.

### Phase 2: Failure Heatmap Tracking
- **The Logic**: If memory fails, the engine starts an "Evidence Log" called a **Heatmap**. It records every attempted selector and why it failed (e.g., "Element not visible", "Timeout", "Overlay blocking").
- **Visual Discovery**: It triggers `VisualAnalyzer.py` to scrape the DOM for new potential matches based on "Semantic Hints" (labels, alt-text, or proximity).

### Phase 3: The AIGO Expert Consultation (God Mode)
If standard retries fail, the system invokes the **AIGO Expert**:
1.  **Artifact Capture**: It takes a high-res Screenshot and a Sanitized HTML (scripts/styles removed).
2.  **The Brain (Gemini)**: It sends these assets to the xAI/Gemini LLM with a highly specific prompt:
    > "You are an Elite Troubleshooting Expert. Mission: Click 'Place Bet'. Here is what we ALREADY tried (The Heatmap). Do NOT try those again. Give me a Primary Path and a Backup Path."
3.  **Path Diversity**: AIGO mandates that the two paths must be DIFFERENT:
    - **Path A (Direct)**: A new, robust CSS selector.
    - **Path B (Action Sequence)**: e.g., "Scroll down 200px, click the 'Accept Cookies' popup, then click the blue button."
    - **Path C (Extraction)**: "Just read the number on the screen and return it; don't bother clicking."

### Phase 4: Self-Healing & Persistence
- Once a path succeeds, AIGO doesn't just forget. 
- It updates the **Knowledge Registry** (`knowledge.json`) and **Learning Weights**.
- This "heals" the codebase in real-time. The next time the bot runs, it will use the new, successful path discovered by AIGO.

---

## 3. Key Components of the "Healer"

| Component | Role | Analogy |
| :--- | :--- | :--- |
| **`aigo_engine.py`** | The Decision Maker. Coordinates the LLM call and path validation. | The Surgeon |
| **`interaction_engine.py`** | The Executioner. Handles the retries and path switching. | The Hands |
| **`visual_analyzer.py`** | The Vision. Sees the screen coordinates and element relationships. | The Eyes |
| **`memory_manager.py`** | The Experience. Remembers what worked and what didn't. | The Brain |
| **`selector_db.py`** | The Registry. Stores the ultimate "Known Truths". | The Dictionary |

---

## 4. Why AIGO is "Ultra-Hardened"
- **Intra-cycle Redundancy**: If the "Primary" suggestion from the AI fails, the system immediately tries the "Backup" without waiting or restarting. This saves minutes of execution time.
- **Context Probing**: If the bot is lost, it runs a `PageAnalyzer` which works like a GPS—it scans the page structure to figure out which "Chapter" of the workflow it should be in.
- **Dynamic Probing**: Before clicking, AIGO "pings" the element to see if it is actually visible or if it's hidden behind a loading spinner.

---

### SUMMARY
**AIGO is the difference between a bot that crashes and a bot that adapts.** It transforms "scraping" into "observing and acting," effectively giving the LeoBook system the ability to "learn" the web interface it interacts with.

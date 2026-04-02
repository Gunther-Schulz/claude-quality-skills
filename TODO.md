# TODO

## Classifier accuracy: evaluation prompts under-trigger

The DO NOT MATCH rule "Design DISCUSSIONS" causes Haiku to reject legitimate evaluation questions that don't use explicit keywords like "evaluate" or "right choice."

**Previously failing (fixed in cb6527e):**
- "should we use redis?" — now triggers ✅
- "should we use redis or sqlite for the cache layer?" — now triggers ✅
- "what do you think about using redis for caching?" — now triggers ✅
- "redis vs sqlite for session storage - which is better?" — now triggers ✅

**Fix:** Broadened category to include COMPARE/CHOOSE/DECIDE with explicit examples. Removed "Design DISCUSSIONS" from DO NOT MATCH. Added NOTE clarifying opinion/comparison questions ARE evaluations. 5/5 pass, 6/6 non-matches still rejected.

**Root cause:** The DO NOT MATCH line "Design DISCUSSIONS (talking about how something should work without asking to write code)" is too broad. "Should we use X or Y?" is asking for evaluation, not idle discussion.

**Possible fixes:**
- Narrow the DO NOT MATCH: "Design DISCUSSIONS that don't ask for a recommendation or comparison"
- Add examples to the CATEGORIES section: "Includes 'should we use X or Y?' comparisons"
- Both

**Risk:** Loosening the filter may cause over-triggering on genuine casual discussion. Need more log data from real usage to calibrate.

**Alternative: configurable sensitivity levels.** Rather than one fixed threshold, allow users to choose how aggressively the classifier triggers:

```bash
CLASSIFIER_SENSITIVITY="normal"  # low, normal, high
```

- **low**: Only explicit keywords ("evaluate", "investigate", "implement", "fix")
- **normal**: Current behavior
- **high**: Trigger on anything plausibly matching ("should we use X?", "what do you think about Y?")

Implementation: done (c56d3c4). Selects different DO NOT MATCH phrasing per level. All configurable via config.sh.

**Observation from initial testing:** "should we use redis or sqlite?" triggered on normal but returned EMPTY on both high and low. Haiku's behavior is sensitive to DO NOT MATCH phrasing in non-obvious ways — different wording doesn't just change the threshold, it can confuse the model into returning nothing. The low and high prompt variants need tuning with dedicated test batteries before they're reliable.

## Classifier accuracy: bare category names

Haiku sometimes returns just the category name (e.g., "critical-thinking") instead of the full line ("Run /critical-thinking before proceeding."). The `CATEGORY_MAP` filter handles this, but it indicates the classifier prompt could be clearer about output format.

## Hook logger: should also be Python

The `claude-hook-logger` is still bash. For consistency, rewrite in Python to match the classifier. Low priority — it's simple and works.

## Statusline color: GROUP_*_COLOR="none" fix

The `GROUP_AUTOSKILLS_COLOR="none"` fix requires claude-worktime commit 97e5788+. Document this version requirement more prominently or detect it at install time.

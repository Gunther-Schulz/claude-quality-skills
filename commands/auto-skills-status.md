Show the current auto-skills configuration and recent classifier activity.

Read ~/.config/claude-auto-skills/config.sh and display:
- CLASSIFIER_ENABLED (on/off)
- CLASSIFIER_SENSITIVITY (low/normal/high)
- CLASSIFIER_MODEL
- CLASSIFIER_EFFORT

Then show the last 5 entries from the classifier log at
~/.local/state/claude-auto-skills/classifier.log (skip DEBUG lines, show only result lines).

Format as a concise summary.

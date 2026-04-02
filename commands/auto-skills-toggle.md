Toggle the auto-skills classifier on or off.

Check the current state in ~/.config/claude-auto-skills/config.sh (CLASSIFIER_ENABLED).
If currently true (or absent/commented), set it to false. If currently false, set it to true.

Use sed to update the file in place. If CLASSIFIER_ENABLED doesn't exist in the file, append it.

After toggling, report the new state.

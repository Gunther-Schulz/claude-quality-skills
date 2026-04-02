#!/usr/bin/env bash
set -euo pipefail

SETTINGS="${HOME}/.claude/settings.json"

GREEN='\033[0;32m'
NC='\033[0m'

echo "Uninstalling claude-auto-skills..."
echo ""

# Uninstall plugin via CLI
if command -v claude &>/dev/null; then
    claude plugin uninstall auto-skills@local 2>/dev/null && echo -e "  ${GREEN}uninstalled${NC}  auto-skills@local" || true
    claude plugin marketplace remove local 2>/dev/null && echo -e "  ${GREEN}removed${NC}      marketplace 'local'" || true
else
    echo "Claude CLI not found. Run these commands inside Claude Code:"
    echo "  /plugin uninstall auto-skills@local"
    echo "  /plugin marketplace remove local"
fi

# Clean up any leftover settings.json entries from older install methods
if command -v jq &>/dev/null && [ -f "$SETTINGS" ]; then
    jq '
      del(.enabledPlugins["auto-skills@local"]) |
      del(.extraKnownMarketplaces["local"])
    ' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"
    echo -e "  ${GREEN}cleaned${NC}    legacy entries from settings.json"
fi

echo ""
echo "Config and logs are NOT removed. To clean up:"
echo "  rm -f ~/.claude/auto-skills.local.md"
echo "  rm -rf \${XDG_STATE_HOME:-\$HOME/.local/state}/claude-auto-skills"
echo "  rm -rf \${XDG_CONFIG_HOME:-\$HOME/.config}/claude-auto-skills  # old config location"

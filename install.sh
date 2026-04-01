#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Installation paths
BIN_DIR="${HOME}/.local/bin"
COMMANDS_SRC="${SCRIPT_DIR}/commands"
COMMANDS_DST="${HOME}/.claude/commands"
CONFIGDIR="${CLAUDE_SKILLS_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/claude-skills}"
STATEDIR="${CLAUDE_SKILLS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/claude-skills}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "Installing claude-auto-skills..."
echo ""

# --- Scripts ---
echo "Scripts:"
mkdir -p "$BIN_DIR"
for script in "${SCRIPT_DIR}"/scripts/*; do
    name="$(basename "$script")"
    cp "$script" "${BIN_DIR}/${name}"
    chmod +x "${BIN_DIR}/${name}"
    echo -e "  ${GREEN}installed${NC} ${BIN_DIR}/${name}"
done
echo ""

# --- Commands ---
echo "Commands:"
mkdir -p "$COMMANDS_DST"
for file in "$COMMANDS_SRC"/*.md; do
    name="$(basename "$file")"
    target="$COMMANDS_DST/$name"
    if [ -L "$target" ]; then
        ln -sf "$file" "$target"
        echo -e "  ${GREEN}updated${NC} $name"
    elif [ -f "$target" ]; then
        echo -e "  ${YELLOW}skipped${NC} $name (file exists, not a symlink — back up or remove first)"
    else
        ln -s "$file" "$target"
        echo -e "  ${GREEN}installed${NC} $name"
    fi
done
echo ""

# --- Config ---
echo "Config:"
mkdir -p "$CONFIGDIR"
if [ ! -f "${CONFIGDIR}/config.sh" ]; then
    cp "${SCRIPT_DIR}/config.sh.example" "${CONFIGDIR}/config.sh"
    echo -e "  ${GREEN}installed${NC} ${CONFIGDIR}/config.sh"
else
    echo -e "  ${YELLOW}kept${NC} ${CONFIGDIR}/config.sh (already exists)"
fi
echo ""

# --- State directory ---
mkdir -p "$STATEDIR"
echo "State: ${STATEDIR}/"
echo ""

# --- Summary ---
echo "Installed paths:"
echo "  Scripts:  ${BIN_DIR}/claude-skill-classifier"
echo "            ${BIN_DIR}/claude-hook-logger"
echo "  Commands: ${COMMANDS_DST}/"
echo "  Config:   ${CONFIGDIR}/config.sh"
echo "  Logs:     ${STATEDIR}/"
echo ""

echo "Available commands:"
for file in "$COMMANDS_SRC"/*.md; do
    echo "  /$(basename "$file" .md)"
done
echo ""

# --- Hook config ---
echo "To enable the classifier hook, add this to hooks.UserPromptSubmit"
echo "in ~/.claude/settings.json:"
echo ""
cat <<HOOK
    {
        "hooks": [
            {
                "type": "command",
                "command": "${BIN_DIR}/claude-hook-logger",
                "timeout": 2
            }
        ]
    },
    {
        "hooks": [
            {
                "type": "command",
                "command": "${BIN_DIR}/claude-skill-classifier",
                "timeout": 15,
                "statusMessage": "Classifying task..."
            }
        ]
    }
HOOK

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_DIR="${HOME}/.local/bin"
COMMANDS_SRC="${SCRIPT_DIR}/commands"
COMMANDS_DST="${HOME}/.claude/commands"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "Uninstalling claude-skills..."
echo ""

# --- Scripts ---
echo "Scripts:"
for script in "${SCRIPT_DIR}"/scripts/*; do
    name="$(basename "$script")"
    target="${BIN_DIR}/${name}"
    if [ -f "$target" ]; then
        rm "$target"
        echo -e "  ${GREEN}removed${NC} $target"
    else
        echo -e "  ${YELLOW}skipped${NC} $target (not found)"
    fi
done
echo ""

# --- Commands ---
echo "Commands:"
for file in "$COMMANDS_SRC"/*.md; do
    name="$(basename "$file")"
    target="$COMMANDS_DST/$name"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$file" ]; then
        rm "$target"
        echo -e "  ${GREEN}removed${NC} $name"
    elif [ -L "$target" ]; then
        echo -e "  ${YELLOW}skipped${NC} $name (symlink points elsewhere)"
    elif [ -f "$target" ]; then
        echo -e "  ${YELLOW}skipped${NC} $name (regular file, not our symlink)"
    else
        echo -e "  ${YELLOW}skipped${NC} $name (not installed)"
    fi
done
echo ""

echo "Note: config and state directories are preserved:"
echo "  Config: ${CLAUDE_SKILLS_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/claude-skills}/"
echo "  State:  ${CLAUDE_SKILLS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/claude-skills}/"
echo ""
echo "Note: remove the classifier hook from ~/.claude/settings.json manually."

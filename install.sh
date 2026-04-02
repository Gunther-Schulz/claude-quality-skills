#!/usr/bin/env bash
set -euo pipefail

echo "Installing claude-quality-skills..."
echo ""

GREEN='\033[0;32m'
NC='\033[0m'

if ! command -v claude &>/dev/null; then
    echo "Claude CLI not found. Run these commands inside Claude Code:"
    echo ""
    echo "  /plugin marketplace add Gunther-Schulz/claude-quality-skills"
    echo "  /plugin install quality-skills@local"
    echo ""
    echo "Then restart Claude Code or run /reload-plugins."
    exit 0
fi

if ! claude plugin marketplace list 2>/dev/null | grep -q '"local"'; then
    claude plugin marketplace add Gunther-Schulz/claude-quality-skills
    echo -e "  ${GREEN}added${NC}      marketplace 'local'"
else
    claude plugin marketplace update local 2>/dev/null
    echo -e "  ${GREEN}updated${NC}    marketplace 'local'"
fi

if claude plugin list 2>/dev/null | grep -q 'quality-skills@local'; then
    claude plugin update quality-skills@local 2>/dev/null
    echo -e "  ${GREEN}updated${NC}    quality-skills@local"
else
    claude plugin install quality-skills@local
    echo -e "  ${GREEN}installed${NC}  quality-skills@local"
fi

echo ""
echo "Restart Claude Code or run /reload-plugins to activate."

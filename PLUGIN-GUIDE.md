# Creating a Claude Code Plugin

A practical guide based on lessons learned converting [claude-quality-skills](https://github.com/Gunther-Schulz/claude-quality-skills) into a proper Claude Code plugin. Covers the pitfalls the official docs don't mention.

## Directory Structure

A plugin distributed through a marketplace needs **two separate layers**: the marketplace (a catalog) and the plugin (the actual extension). Their `.claude-plugin/` directories must never be mixed.

```
repo-root/                         # ← marketplace root
├── .claude-plugin/
│   └── marketplace.json           # marketplace definition ONLY
├── plugin/                        # ← plugin root
│   ├── .claude-plugin/
│   │   └── plugin.json            # plugin definition ONLY
│   ├── commands/                   # slash commands (.md files)
│   ├── skills/                     # auto-invoked skills
│   │   └── my-skill/
│   │       └── SKILL.md
│   ├── hooks/
│   │   ├── hooks.json              # hook configuration
│   │   └── scripts/                # hook scripts
│   └── agents/                     # subagent definitions (.md files)
├── install.sh                      # optional migration/setup helper
└── README.md
```

### Why separate?

Claude Code loads `plugin.json` and `marketplace.json` from the same `.claude-plugin/` directory. When both exist together, it reads `plugin.json` when it expects `marketplace.json` and fails with a misleading schema validation error (`owner: expected object, received undefined`).

The official marketplace (`claude-plugins-official`) follows this pattern: marketplace.json at the repo root, individual plugins in subdirectories.

## marketplace.json

Located at `.claude-plugin/marketplace.json` in the repo root:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "my-marketplace",
  "description": "Short description",
  "owner": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "plugins": [
    {
      "name": "my-plugin",
      "description": "What the plugin does",
      "source": "./plugin"
    }
  ]
}
```

**Required fields:** `name`, `owner` (with `name`), `plugins` array. Each plugin entry needs `name` and `source`.

The `source` is a relative path from the repo root to the plugin directory. Must start with `./`.

## plugin.json

Located at `plugin/` (or wherever `source` points) under `.claude-plugin/plugin.json`:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What the plugin does",
  "author": {
    "name": "Your Name"
  }
}
```

Only `name` is strictly required. The `name` here determines the skill namespace — skills will be available as `/my-plugin:skill-name`.

## Components

### Skills (auto-invoked)

Skills live in `skills/<skill-name>/SKILL.md`. Claude automatically invokes them based on the `description` field in the frontmatter.

**Naming convention:** Use descriptive names without the plugin prefix. The namespace already provides context (`my-plugin:code-review`, not `my-plugin:my-plugin-code-review`). Avoid skill names that share a prefix with the plugin name — due to [#29520](https://github.com/anthropics/claude-code/issues/29520), non-namespaced duplicates appear in autocomplete and would cluster with the plugin's namespaced entries.

**Description convention:** Use third-person with specific trigger phrases in quotes:

```markdown
---
name: code-review
description: This skill should be used when the user asks to "review code", "check this PR", "analyze code quality", or requests feedback on implementation patterns.
version: 1.0.0
---

When reviewing code, check for:
1. Code organization
2. Error handling
3. Security concerns
```

**Progressive disclosure:** For large skills, put detailed reference material in a `references/` subdirectory alongside `SKILL.md`. Reference them in prose: "For detailed patterns, see `references/patterns.md`".

### Commands (user-invoked)

Commands live in `commands/<name>.md`. They become slash commands namespaced under the plugin: `/my-plugin:command-name`.

```markdown
---
description: Does something useful
allowed-tools: Bash, Read
disable-model-invocation: true
argument-hint: [option1|option2]
---

Handle the command. User argument: $ARGUMENTS
```

`disable-model-invocation: true` means only the user can trigger it (not the model).

### Hooks

Hooks live in `hooks/hooks.json`. **Critical difference from settings.json:** plugin hooks require a `"hooks"` wrapper key.

```json
{
  "description": "What these hooks do",
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/my-hook.sh",
            "timeout": 10,
            "statusMessage": "Running hook..."
          }
        ]
      }
    ]
  }
}
```

Without the `"hooks"` wrapper, you get: `Hook load failed: expected record, received undefined`.

**Use `${CLAUDE_PLUGIN_ROOT}`** for all paths in hooks.json. It resolves to the plugin's cached install location.

### Hook scripts — stderr pitfall

Claude Code treats **any stderr output** from hook scripts as a hook error, even when the script exits 0 ([#34859](https://github.com/anthropics/claude-code/issues/34859)). Silence stderr early:

**Bash:**
```bash
#!/usr/bin/env bash
exec 2>/dev/null
# ... rest of script
```

**Python:**
```python
#!/usr/bin/env python3
import os, sys
sys.stderr = open(os.devnull, "w")
# ... rest of script
```

After a session restart, cached hook errors clear. But without stderr silencing, they reappear on every message.

## Plugin Configuration (`.local.md` pattern)

Plugins that need user-configurable settings should use `.claude/plugin-name.local.md` files with YAML frontmatter. This is the standard pattern documented by the `plugin-dev` plugin.

```markdown
---
enabled: true
sensitivity: normal
model: claude-haiku-4-5-20251001
custom_option: value
---

Optional markdown body for notes (ignored by the plugin).
```

**Location precedence:** project `.claude/plugin-name.local.md` > global `~/.claude/plugin-name.local.md`. This gives per-project overrides with a global fallback.

**Why not `config.sh` or env vars?**
- `.local.md` is the plugin ecosystem convention (readable by hooks, commands, and skills)
- Per-project support without environment variable juggling
- YAML frontmatter is parseable in both bash (`sed`) and Python (simple regex, no PyYAML needed)
- `.local.md` files should be in `.gitignore` (user-specific, not shared)

**Reading from hooks:** In Python hooks, parse the frontmatter with a simple regex. In bash hooks, use `sed -n '/^---$/,/^---$/{...}'`. No external dependencies needed.

## Installation Flow

### Publishing

Push your repo to GitHub. The repo must have `.claude-plugin/marketplace.json` at the root.

### Installing

Inside Claude Code:

```
/plugin marketplace add owner/repo
/plugin install my-plugin@my-marketplace
/reload-plugins
```

Or automate from the shell using Claude Code's CLI:

```bash
claude plugin marketplace add owner/repo
claude plugin install my-plugin@my-marketplace
```

This allows install.sh scripts to handle the full setup without manual `/plugin` commands.

The marketplace name comes from the `name` field in `marketplace.json`. The plugin name comes from the `name` field in the plugin entry.

### Updating after changes

After pushing changes to GitHub:

```
/plugin marketplace update my-marketplace
/plugin uninstall my-plugin@my-marketplace
/plugin install my-plugin@my-marketplace
/reload-plugins
```

`marketplace update` pulls the latest marketplace.json but does **not** update already-installed plugins. You must uninstall and reinstall to get new plugin files.

### Local development

Use `--plugin-dir` for testing without the marketplace cycle:

```bash
claude --plugin-dir ./plugin
```

This loads the plugin directly from the local directory. Use `/reload-plugins` to pick up changes without restarting.

## When NOT to Use a Plugin

Not every Claude Code extension belongs in a plugin. Plugins are best for **self-contained** extensions where all functionality lives within the plugin directory.

**Good fit for a plugin:**
- Skills, commands, and hooks with no external dependencies
- Tools that don't need CLI access outside Claude Code
- Extensions that don't configure `statusLine` or other settings.json keys plugins can't set

**Bad fit for a plugin (keep as install.sh-managed tool):**
- System utilities that need a CLI binary in `$PATH` (e.g., `~/.local/bin/my-tool`)
- Tools that configure `statusLine` (plugins can only set the `agent` key in settings.json)
- Scripts with heavy external state (XDG data dirs, config files) that must survive plugin reinstalls
- Tools where hooks just call an external binary — the plugin adds indirection without benefit

**The test:** If after converting to a plugin, install.sh still handles most of the setup (copying scripts, configuring settings.json, managing external state), the plugin layer is adding complexity without value.

## Session Restart Required

After installing or reinstalling a plugin, `/reload-plugins` loads the new skills, commands, and hooks. However, **hook errors from the previous load may persist in the session**. If you see stale "hook error" messages after fixing an issue, restart Claude Code — a fresh session clears them.

## Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| `marketplace.json` and `plugin.json` in same `.claude-plugin/` | `owner: expected object, received undefined` | Separate into marketplace root + plugin subdirectory |
| hooks.json without `"hooks"` wrapper | `Hook load failed: expected record, received undefined` | Wrap events under `{"hooks": {...}}` |
| Hook script writes to stderr | `UserPromptSubmit hook error` on every message | Add `exec 2>/dev/null` (bash) or `sys.stderr = open(os.devnull, "w")` (python) |
| Changed plugin on GitHub but not reinstalled | Old behavior persists | `marketplace update` + uninstall + reinstall |
| `directory` source in `extraKnownMarketplaces` | `owner: expected object, received undefined` on install | Use GitHub source (`/plugin marketplace add owner/repo`) instead |
| `enabledPlugins` in settings.json without `/plugin install` | Plugin doesn't load | Must install via `/plugin install`, not just enable in settings |
| Marketplace and plugin have the same name | Skills appear both namespaced and non-namespaced | Use different names (e.g., marketplace `coding-clippy`, plugin `clippy`) |
| `old-skills/` or archive dirs with SKILL.md in repo | Stale skills appear as non-namespaced | Delete or rename SKILL.md files outside `plugin/`; they get cloned into marketplace cache |

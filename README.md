# claude-quality-skills

Quality checklists for Claude Code. Skills are auto-discovered based on task context — when you ask Claude to write code, investigate a bug, or evaluate a proposal, the relevant checklist loads automatically.

## Why

Claude Code follows instructions but doesn't consistently self-check. It can skip consumer analysis before modifying interfaces, agree with proposals without challenging assumptions, or make claims without showing supporting data. These skills force verifiable checkpoints — tagged markers (📋, ✅, ⚖️) that you can spot-check — and Claude loads them automatically via built-in skill auto-discovery.

## Skills

| Skill | When to use |
|-------|-------------|
| `/quality-skills:code-quality` | Before writing or modifying code — requirements review, consumer analysis, fallback tracing, pattern search |
| `/quality-skills:critical-thinking` | During investigation, debugging, or analysis — claim verification, backward traces, hypothesis testing |
| `/quality-skills:critical-evaluation` | When evaluating proposals — challenge assumptions before agreeing |
| `/quality-skills:skill-design` | When writing or reviewing skills, rules, checklists, or prompt templates |

## Installation

```bash
git clone https://github.com/Gunther-Schulz/claude-quality-skills.git
cd claude-quality-skills
./install.sh
```

This handles everything: config setup, migration from older installs, marketplace registration, and plugin installation via the `claude` CLI.

Restart Claude Code or run `/reload-plugins` to activate.

### What the plugin provides

- **4 skills** — auto-discovered by Claude based on task context
- **1 command** — `/quality-skills:quality-skills` for management

Skills are loaded automatically by Claude Code's built-in auto-discovery when the task matches the skill description. No hooks or external classifier needed.

## Management

Use `/quality-skills:quality-skills` to check which skills are available.

> **Note:** The classifier hook (Haiku-based prompt classification) is preserved in the
> [`classifier-hooks`](https://github.com/Gunther-Schulz/claude-quality-skills/tree/classifier-hooks)
> branch. It was removed from main because Claude Code's built-in skill auto-discovery
> handles the common cases without the latency and cost of a subprocess call. If auto-discovery
> proves insufficient for edge cases, the classifier can be restored from that branch.

## Updating

```bash
claude plugin marketplace update local
claude plugin update quality-skills@local
```

Then `/reload-plugins` or restart Claude Code.

## Development

Skills live in `plugin/`:

```
plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── quality-skills.md            # /quality-skills:quality-skills management command
└── skills/
    ├── code-quality/SKILL.md
    ├── critical-thinking/SKILL.md
    ├── critical-evaluation/SKILL.md
    └── skill-design/SKILL.md
```

After editing, push to GitHub and update:

```bash
git add -A && git commit -m "..." && git push
claude plugin marketplace update local
claude plugin update quality-skills@local
```

Then `/reload-plugins` or restart Claude Code.

## Uninstalling

```
/plugin uninstall quality-skills@local
/plugin marketplace remove local
```

Config is preserved. To remove:
```bash
rm -f ~/.claude/quality-skills.local.md
rm -rf ~/.local/state/claude-quality-skills
```

## Effectiveness caveat

There is no way to prove these skills improve Claude's output quality. The skills force Claude to produce visible markers (📋, ✅, ⚖️) that make its verification steps auditable, but whether that changes actual thoroughness vs just documenting what it would have done anyway is unknown. The only reliable signal is your correction frequency over time — if you stop catching "you forgot to update X" mistakes, the skills are working. If the same mistakes persist, they're cosmetics.

## License

MIT

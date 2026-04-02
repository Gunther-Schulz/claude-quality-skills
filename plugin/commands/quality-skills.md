---
name: quality-skills
description: Show available quality-skills and their descriptions.
allowed-tools: Read, Bash
disable-model-invocation: true
---

Show a summary of the quality-skills plugin.

List the installed skills by reading the SKILL.md frontmatter from each skill directory in this plugin. For each skill, show:
- Skill name (namespaced as `quality-skills:<name>`)
- Description (from frontmatter)

Also note: skills are auto-discovered by Claude Code based on task context. No manual invocation needed for normal use. Explicit invocation via `/quality-skills:<name>` is available if needed.

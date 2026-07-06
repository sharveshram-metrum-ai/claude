# Claude Code status line

Custom Claude Code status line. Renders a bar like:

```
🖥 host │ 📁 project │ 🌿 branch ✓ │ 🤖 Opus │ 🧠 79% left │ 🎭 default │ 🎀 ponytail:ultra │ 🧩 ponytail,superpowers │ MCP:context7 │ ⏳21% · 7m
```

| Segment | Meaning |
|---|---|
| 🖥 | machine hostname |
| 📁 | current project folder |
| 🌿 | git branch + sync (`✓` in sync · `⇡` ahead · `⇣` behind · `⚠` no upstream) |
| 🤖 | active model |
| 🧠 | context window **remaining** (available) % |
| 🎭 | active output style |
| 🎀 | ponytail mode — shown only while active (reads `~/.claude/.ponytail-active`) |
| 🧩 | installed/enabled plugins (from `settings.json` `enabledPlugins`) |
| MCP: | MCP servers configured for the project (hidden when none) |
| ⏳ | 5-hour usage window: `% of quota used · time until reset` |

Data-dependent segments (🧠 and ⏳) only appear after the first API call in a session populates them.

## Install (per machine, all projects)

```bash
bash install-statusline.sh
```

Writes `~/.claude/statusline-command.sh` and adds the `statusLine` entry to
`~/.claude/settings.json` (merging, not overwriting).

## Install (per project, travels with the repo)

Copy `statusline-command.sh` into the repo's `.claude/` folder and add to
`.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash \"$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/statusline-command.sh\""
  }
}
```

## Requirements

`jq` and `git` must be installed. Takes effect on the next prompt.

# Claude Code status line

Custom Claude Code status line. Renders a bar like:

```
🖥 host │ 📁 project │ 🌿 branch ✓ │ 🤖 Opus │ 🧠 92% │ 🎭 default │ ⏳4h58m
```

| Segment | Meaning |
|---|---|
| 🖥 | machine hostname |
| 📁 | current project folder |
| 🌿 | git branch + sync (`✓` in sync · `⇡` ahead · `⇣` behind · `⚠` no upstream) |
| 🤖 | active model |
| 🧠 | context window remaining % |
| 🎭 | active output style |
| MCP: | MCP servers configured for the project (hidden when none) |
| ⏳ | time until the 5-hour usage window resets |

## Install (per machine, all projects)

```bash
bash install-statusline.sh
```

This writes `~/.claude/statusline-command.sh` and adds the `statusLine` entry to
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





git clone https://github.com/sharveshram-metrum-ai/claude.git
cd claude
bash install-statusline.sh
That installs it machine-wide (all your projects). Just needs jq and git present. Done â no gate, works immediately.

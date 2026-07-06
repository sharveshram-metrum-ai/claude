#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.project_dir // .cwd // .workspace.current_dir // empty')
[ -z "$cwd" ] && cwd="$(pwd)"

host=$(hostname -s)                    # 🖥
proj=$(basename "$cwd")                # 📁

# 🌿 branch + sync status vs upstream
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null); branch=${branch##*/}
sync=""
counts=$(git -C "$cwd" rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
if [ -n "$counts" ]; then
  behind=$(echo "$counts" | awk '{print $1}'); ahead=$(echo "$counts" | awk '{print $2}')
  if [ "${ahead:-0}" -eq 0 ] && [ "${behind:-0}" -eq 0 ]; then sync="✓"
  else
    [ "${ahead:-0}" -gt 0 ]  && sync="⇡$ahead"
    [ "${behind:-0}" -gt 0 ] && sync="$sync⇣$behind"
  fi
elif [ -n "$branch" ]; then
  sync="⚠"
fi

# 🤖 model (first word)
model=$(echo "$input" | jq -r '.model.display_name // empty'); model=${model%% *}

# 🧠 context remaining %
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# 🎭 active output style
style=$(echo "$input" | jq -r '.output_style.name // empty')

# MCP: only servers actually configured for THIS project (hidden when none)
mcp=$( { jq -r '(.mcpServers // {}) | keys[]?' "$cwd/.mcp.json" 2>/dev/null; \
         jq -r '(.mcpServers // {}) | keys[]?' "$cwd/.claude/settings.json" 2>/dev/null; \
         jq -r '(.mcpServers // {}) | keys[]?' "$cwd/.claude/settings.local.json" 2>/dev/null; \
         jq -r --arg d "$cwd" '(.projects[$d].mcpServers // {}) | keys[]?' "$HOME/.claude.json" 2>/dev/null; \
       } | sed '/^$/d' | sort -u | paste -sd, - )

# ⏳ time until 5-hour usage window resets (real value from rate_limits)
resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
reset=""
if [ -n "$resets_at" ]; then
  left=$(( resets_at - $(date +%s) ))
  if [ "$left" -le 0 ]; then reset="⏳reset"
  elif [ "$left" -ge 3600 ]; then reset=$(printf '⏳%dh%02dm' $((left/3600)) $(((left%3600)/60)))
  else reset=$(printf '⏳%dm' $((left/60))); fi
fi

segs=()
segs+=("🖥 $host")
segs+=("📁 $proj")
[ -n "$branch" ]    && segs+=("🌿 $branch${sync:+ $sync}")
[ -n "$model" ]     && segs+=("🤖 $model")
[ -n "$remaining" ] && segs+=("🧠 $(printf '%.0f' "$remaining")%")
[ -n "$style" ]     && segs+=("🎭 $style")
[ -n "$mcp" ]       && segs+=("MCP:$mcp")
[ -n "$reset" ]     && segs+=("$reset")

out=""; for s in "${segs[@]}"; do [ -n "$out" ] && out="$out │ $s" || out="$s"; done
printf '%s' "$out"

#!/usr/bin/env bash
# Portable installer for the custom Claude Code status line.
# Usage:  bash install-statusline.sh
set -e
CLAUDE_DIR="$HOME/.claude"; mkdir -p "$CLAUDE_DIR"
for dep in jq git; do command -v "$dep" >/dev/null 2>&1 || echo "⚠  '$dep' not found — some segments will be blank."; done
cat > "$CLAUDE_DIR/statusline-command.sh" <<'STATUSLINE_EOF'
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

# 🧠 context available (remaining) %
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# 🎭 active output style
style=$(echo "$input" | jq -r '.output_style.name // empty')

# MCP: only servers actually configured for THIS project (hidden when none)
mcp=$( { jq -r '(.mcpServers // {}) | keys[]?' "$cwd/.mcp.json" 2>/dev/null; \
         jq -r '(.mcpServers // {}) | keys[]?' "$cwd/.claude/settings.json" 2>/dev/null; \
         jq -r '(.mcpServers // {}) | keys[]?' "$cwd/.claude/settings.local.json" 2>/dev/null; \
         jq -r --arg d "$cwd" '(.projects[$d].mcpServers // {}) | keys[]?' "$HOME/.claude.json" 2>/dev/null; \
       } | sed '/^$/d' | sort -u | paste -sd, - )

# 🎀 ponytail mode — flag file exists only while ponytail is active
pony=""
_pflag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.ponytail-active"
[ -f "$_pflag" ] && pony=$(head -n1 "$_pflag" | tr -d '[:space:]')

# 🧩 enabled plugins (generic — works for any plugin; shows what's ON, not what's firing)
plugins=$(jq -r '(.enabledPlugins // {}) | to_entries[] | select(.value==true) | .key | sub("@.*";"")' "$HOME/.claude/settings.json" 2>/dev/null | sort -u | paste -sd, -)

# ⏳ 5-hour usage window: % of quota used + time until reset
resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
five_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
reset=""
if [ -n "$resets_at" ]; then
  left=$(( resets_at - $(date +%s) ))
  if [ "$left" -le 0 ]; then t="reset"
  elif [ "$left" -ge 3600 ]; then t=$(printf '%dh%02dm' $((left/3600)) $(((left%3600)/60)))
  else t=$(printf '%dm' $((left/60))); fi
  if [ -n "$five_used" ]; then reset=$(printf '⏳%.0f%% · %s' "$five_used" "$t"); else reset="⏳$t"; fi
fi

segs=()
segs+=("🖥 $host")
segs+=("📁 $proj")
[ -n "$branch" ]    && segs+=("🌿 $branch${sync:+ $sync}")
[ -n "$model" ]     && segs+=("🤖 $model")
[ -n "$remaining" ] && segs+=("🧠 $(printf '%.0f' "$remaining")% left")
[ -n "$style" ] && [ "$style" != "default" ] && segs+=("🎭 $style")
[ -n "$pony" ]      && segs+=("🎀 ponytail$([ "$pony" = full ] || [ -z "$pony" ] && echo "" || echo ":$pony")")
[ -n "$plugins" ]   && segs+=("🧩 $plugins")
[ -n "$mcp" ]       && segs+=("MCP:$mcp")
[ -n "$reset" ]     && segs+=("$reset")

out=""; for s in "${segs[@]}"; do [ -n "$out" ] && out="$out │ $s" || out="$s"; done
printf '%s' "$out"
STATUSLINE_EOF
chmod +x "$CLAUDE_DIR/statusline-command.sh"
echo "✓ wrote $CLAUDE_DIR/statusline-command.sh"
SETTINGS="$CLAUDE_DIR/settings.json"; [ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
tmp=$(mktemp)
jq '.statusLine = {type:"command", command:"bash \"$HOME/.claude/statusline-command.sh\""}' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
echo "✓ set statusLine in $SETTINGS — done."

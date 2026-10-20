#!/usr/bin/env bash
# Links each skill in ./skills into the user-level folders that coding agents read.
# ~/.claude/skills reaches Claude Code, Cursor, OpenCode, and Muse Code.
# ~/.agents/skills reaches Codex, Cursor, OpenCode, Muse Code, and Pi.
# Run with --remove to delete the links again.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
targets=("$HOME/.claude/skills" "$HOME/.agents/skills")
[ -d "$HOME/.grok" ] && targets+=("$HOME/.grok/skills")
[ -d "$HOME/.gemini/antigravity" ] && targets+=("$HOME/.gemini/antigravity/skills")

for skill in "$repo"/skills/*/; do
  skill="${skill%/}"
  [ -f "$skill/SKILL.md" ] || continue
  name="$(basename "$skill")"
  for target in "${targets[@]}"; do
    link="$target/$name"
    if [ "${1:-}" = "--remove" ]; then
      if [ -L "$link" ] && [ "$(readlink "$link")" = "$skill" ]; then
        rm "$link"
        echo "removed $link"
      fi
      continue
    fi
    if [ -e "$link" ] && [ ! -L "$link" ]; then
      echo "skipped $link because a real folder is already there" >&2
      continue
    fi
    mkdir -p "$target"
    ln -sfn "$skill" "$link"
    echo "linked $link"
  done
done

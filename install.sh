#!/usr/bin/env bash
# Makes ~/.agents/skills the one skill folder for every coding agent on this machine.
# Codex, Cursor, Muse Code, OpenCode, and Pi read ~/.agents/skills directly.
# Claude Code reads only ~/.claude/skills, so every skill in ~/.agents/skills gets a link there.
# Grok Build gets the same links in ~/.grok/skills when it is installed.
# Antigravity reads ~/.gemini/config/skills, so that folder becomes a link to ~/.agents/skills.
# The skills in this repo are linked into ~/.agents/skills first.
# Run it again after adding or removing a skill in ~/.agents/skills.
# --check prints what would change and exits 1 when anything would. --remove deletes every link this script makes.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hub="$HOME/.agents/skills"
antigravity="$HOME/.gemini/config/skills"
old_antigravity="$HOME/.gemini/antigravity/skills"
mode="${1:-install}"
case "$mode" in
  install | --check | --remove) ;;
  *)
    echo "usage: install.sh [--check | --remove]" >&2
    exit 2
    ;;
esac

farms=("$HOME/.claude/skills")
[ -d "$HOME/.grok" ] && farms+=("$HOME/.grok/skills")

changes=0
problems=0

change() {
  changes=$((changes + 1))
  if [ "$mode" = --check ]; then
    echo "would $1"
    return
  fi
  local description="$1"
  shift
  "$@"
  echo "$description"
}

problem() {
  problems=$((problems + 1))
  echo "skipped $1" >&2
}

resolve() {
  (cd -P "$1" 2>/dev/null && pwd -P)
}

present() {
  [ -e "$1" ] || [ -L "$1" ]
}

owned() {
  [ -L "$1" ] || return 1
  case "$(readlink "$1")" in
    "$hub"/* | "$repo"/skills/*) return 0 ;;
  esac
  return 1
}

link_folder() {
  mkdir -p "$(dirname "$2")"
  ln -s "$1" "$2"
}

[ "$mode" = install ] && mkdir -p "$hub"

for skill in "$repo"/skills/*/; do
  skill="${skill%/}"
  [ -f "$skill/SKILL.md" ] || continue
  link="$hub/$(basename "$skill")"
  if [ "$mode" = --remove ]; then
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$skill" ]; then change "remove $link" rm "$link"; fi
  elif [ -L "$link" ] && [ "$(readlink "$link")" = "$skill" ]; then
    :
  elif present "$link"; then
    problem "$link because another skill with this name is already there"
  else
    change "link $link" ln -s "$skill" "$link"
  fi
done

for farm in "${farms[@]}"; do
  if [ "$mode" = --remove ]; then
    for link in "$farm"/*; do
      if owned "$link"; then change "remove $link" rm "$link"; fi
    done
    continue
  fi
  [ "$mode" = install ] && mkdir -p "$farm"
  for entry in "$hub"/*; do
    name="$(basename "$entry")"
    [ -f "$entry/SKILL.md" ] || continue
    link="$farm/$name"
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$entry" ]; then
      continue
    elif [ -L "$link" ] && [ "$(resolve "$link")" = "$(resolve "$entry")" ]; then
      change "repoint $link" ln -sfn "$entry" "$link"
    elif present "$link"; then
      problem "$link because a different skill with this name is already there"
    else
      change "link $link" ln -s "$entry" "$link"
    fi
  done
  for link in "$farm"/*; do
    if owned "$link" && [ ! -e "$link" ]; then change "remove stale $link" rm "$link"; fi
  done
done

if [ "$mode" = --remove ]; then
  if [ -L "$antigravity" ] && [ "$(readlink "$antigravity")" = "$hub" ]; then change "remove $antigravity" rm "$antigravity"; fi
elif [ -L "$antigravity" ] && [ "$(readlink "$antigravity")" = "$hub" ]; then
  :
elif present "$antigravity"; then
  problem "$antigravity because it is not a link to $hub. Move its skills into $hub, delete it, and run this again"
else
  change "link $antigravity" link_folder "$hub" "$antigravity"
fi

for link in "$old_antigravity"/*; do
  if owned "$link"; then change "remove $link, since Antigravity reads $antigravity" rm "$link"; fi
done

if [ "$changes" -eq 0 ] && [ "$problems" -eq 0 ]; then echo "nothing to change"; fi
if [ "$problems" -gt 0 ] || { [ "$mode" = --check ] && [ "$changes" -gt 0 ]; }; then exit 1; fi

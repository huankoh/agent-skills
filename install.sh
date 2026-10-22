#!/usr/bin/env bash
# Claude Code does not read ~/.agents/skills, so every skill there gets a link in ~/.claude/skills.
# Antigravity reads ~/.gemini/config/skills, so that folder becomes a link to ~/.agents/skills.
# --check prints what would change and exits 1 when anything would change or conflict.
# --remove deletes the links this script makes: <folder>/<name> pointing at ~/.agents/skills/<name> or this repo's skills/<name>.
# A broken link to some other */skills/<name> is taken for one an older clone made, and is repointed rather than reported.
set -euo pipefail

repo="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
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
if [ ! -d "$repo/skills" ]; then
  echo "install.sh found no skills folder next to it. Run it from the repo clone, not through a link to the script." >&2
  exit 2
fi

farms=("$HOME/.claude/skills")
if [ -d "$HOME/.grok" ]; then farms+=("$HOME/.grok/skills"); fi

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

same_folder() {
  local a b
  a="$(resolve "$1")"
  b="$(resolve "$2")"
  [ -n "$a" ] && [ "$a" = "$b" ]
}

ours() {
  [ -L "$1" ] || return 1
  local name target
  name="$(basename "$1")"
  target="$(readlink "$1")"
  [ "$target" = "$hub/$name" ] || [ "$target" = "$repo/skills/$name" ]
}

clone_shaped() {
  case "$(readlink "$1")" in
    */skills/"$(basename "$1")") return 0 ;;
  esac
  return 1
}

make_link() {
  mkdir -p "$(dirname "$2")"
  ln -s "$1" "$2"
}

sync_link() {
  local link="$1" target="$2"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
    return
  elif [ -L "$link" ] && { same_folder "$link" "$target" || { [ ! -e "$link" ] && clone_shaped "$link"; }; }; then
    change "repoint $link" ln -sfn "$target" "$link"
  elif present "$link"; then
    problem "$link because something this script did not make is already there"
  else
    change "link $link" make_link "$target" "$link"
  fi
}

prune_stale() {
  local link
  for link in "$1"/*; do
    if ours "$link" && [ ! -e "$link" ]; then change "remove stale $link" rm "$link"; fi
  done
}

remove_ours() {
  local link
  for link in "$1"/*; do
    if ours "$link"; then change "remove $link" rm "$link"; fi
  done
}

skill_names() {
  local entry name seen=" "
  for entry in "$hub"/* "$repo"/skills/*; do
    name="$(basename "$entry")"
    [ -f "$entry/SKILL.md" ] || continue
    case "$seen" in *" $name "*) continue ;; esac
    seen="$seen$name "
    echo "$name"
  done
}

if [ "$mode" = --remove ]; then
  for farm in "${farms[@]}"; do
    if ! same_folder "$farm" "$hub"; then remove_ours "$farm"; fi
  done
  if ! same_folder "$old_antigravity" "$hub"; then remove_ours "$old_antigravity"; fi
  remove_ours "$hub"
  if [ -L "$antigravity" ] && same_folder "$antigravity" "$hub"; then change "remove $antigravity" rm "$antigravity"; fi
else
  for skill in "$repo"/skills/*/; do
    skill="${skill%/}"
    if [ -f "$skill/SKILL.md" ]; then sync_link "$hub/$(basename "$skill")" "$skill"; fi
  done
  prune_stale "$hub"

  for farm in "${farms[@]}"; do
    if same_folder "$farm" "$hub"; then continue; fi
    while IFS= read -r name; do
      sync_link "$farm/$name" "$hub/$name"
    done < <(skill_names)
    prune_stale "$farm"
  done

  sync_link "$antigravity" "$hub"
  if ! same_folder "$old_antigravity" "$hub"; then remove_ours "$old_antigravity"; fi
fi

if [ "$changes" -eq 0 ] && [ "$problems" -eq 0 ]; then echo "nothing to change"; fi
if [ "$problems" -gt 0 ] || { [ "$mode" = --check ] && [ "$changes" -gt 0 ]; }; then exit 1; fi

#!/usr/bin/env bash
# Runs install.sh against throwaway home folders, one per case, and exits 1 when any case fails.
# Usage: bash checks/test_install.sh
set -euo pipefail

repo="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
homes=()
failures=0

fresh_home() {
  local home
  home="$(mktemp -d "${TMPDIR:-/tmp}/agent-skills-test.XXXXXX")"
  home="$(cd -P "$home" && pwd -P)"
  homes+=("$home")
  H="$home"
}

run() {
  HOME="$H" "$BASH" "$repo/install.sh" "$@"
}

status_of() {
  local status=0
  "$@" >/dev/null 2>&1 || status=$?
  echo "$status"
}

link_is() {
  [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]
}

absent() {
  [ ! -e "$1" ] && [ ! -L "$1" ]
}

expect() {
  local label="$1"
  shift
  if "$@"; then
    echo "ok   $label"
  else
    echo "FAIL $label"
    failures=$((failures + 1))
  fi
}

fresh_home
run >/dev/null
expect "install links the repo skills into the hub" link_is "$H/.agents/skills/coding-standards" "$repo/skills/coding-standards"
expect "install gives Claude Code a link to the hub entry" link_is "$H/.claude/skills/coding-standards" "$H/.agents/skills/coding-standards"
expect "install links the Antigravity folder to the hub" link_is "$H/.gemini/config/skills" "$H/.agents/skills"
expect "a second install changes nothing" [ "$(run)" = "nothing to change" ]
expect "--check passes after install" [ "$(status_of run --check)" = 0 ]

fresh_home
expect "--check on a fresh home exits 1" [ "$(status_of run --check)" = 1 ]
expect "--check previews the Claude Code links" grep -q "would link $H/.claude/skills/coding-standards" <<<"$(run --check || true)"
expect "--check creates nothing" absent "$H/.agents"

fresh_home
mkdir -p "$H/.agents/skills" "$H/.claude"
ln -s "$H/.agents/skills" "$H/.claude/skills"
run >/dev/null
expect "a Claude Code folder linked to the hub keeps every hub skill" test -f "$H/.agents/skills/coding-standards/SKILL.md"

fresh_home
mkdir -p "$H/.agents/skills" "$H/.gemini/antigravity"
ln -s "$H/.agents/skills" "$H/.gemini/antigravity/skills"
run >/dev/null
expect "an old Antigravity folder linked to the hub keeps every hub skill" test -f "$H/.agents/skills/prune-tests/SKILL.md"

fresh_home
mkdir -p "$H/.agents/skills/mine"
printf -- '---\nname: mine\ndescription: A skill the user keeps in the hub.\n---\n' >"$H/.agents/skills/mine/SKILL.md"
run >/dev/null
expect "install gives Claude Code a link to the user's own hub skill" link_is "$H/.claude/skills/mine" "$H/.agents/skills/mine"
ln -s "$repo/skills/coding-standards" "$H/.claude/skills/my-alias"
run --remove >/dev/null
expect "--remove keeps a link the user made" test -L "$H/.claude/skills/my-alias"
expect "--remove keeps the user's own hub skill" test -f "$H/.agents/skills/mine/SKILL.md"
expect "--remove takes out the Claude Code links it made" absent "$H/.claude/skills/mine"
expect "--remove takes out the hub links to the repo" absent "$H/.agents/skills/coding-standards"
expect "--remove takes out the Antigravity folder link" absent "$H/.gemini/config/skills"

fresh_home
run >/dev/null
ln -s "$repo/skills/retired-skill" "$H/.agents/skills/retired-skill"
ln -s "$H/.agents/skills/retired-skill" "$H/.claude/skills/retired-skill"
expect "--check reports the hub link to a retired repo skill" grep -q "would remove stale $H/.agents/skills/retired-skill" <<<"$(run --check || true)"
run >/dev/null
expect "install removes the hub link to a retired repo skill" absent "$H/.agents/skills/retired-skill"
expect "install removes the Claude Code link to a retired skill" absent "$H/.claude/skills/retired-skill"

fresh_home
mkdir -p "$H/old-clone"
cp -R "$repo/install.sh" "$repo/skills" "$H/old-clone/"
HOME="$H" "$BASH" "$H/old-clone/install.sh" >/dev/null
rm -rf "$H/old-clone"
run >/dev/null
expect "after the clone moves, hub links point at the new clone" link_is "$H/.agents/skills/coding-standards" "$repo/skills/coding-standards"
expect "after the clone moves, Claude Code still reaches the skill" test -f "$H/.claude/skills/coding-standards/SKILL.md"

fresh_home
mkdir -p "$H/.agents/skills" "$H/.gemini/config"
ln -s "$H/.agents/skills/" "$H/.gemini/config/skills"
run >/dev/null
expect "an Antigravity link written with a trailing slash is accepted" [ "$(status_of run --check)" = 0 ]

fresh_home
mkdir -p "$H/.claude/skills/coding-standards"
echo keep >"$H/.claude/skills/coding-standards/SKILL.md"
expect "a real folder in the way makes install exit 1" [ "$(status_of run)" = 1 ]
expect "install leaves that real folder untouched" grep -q keep "$H/.claude/skills/coding-standards/SKILL.md"

fresh_home
mkdir -p "$H/.claude/skills"
ln -s "$H/unmounted-drive/coding-standards" "$H/.claude/skills/coding-standards"
expect "a broken link the user made makes install exit 1" [ "$(status_of run)" = 1 ]
expect "install leaves a broken link the user made in place" link_is "$H/.claude/skills/coding-standards" "$H/unmounted-drive/coding-standards"

fresh_home
mkdir -p "$H/personal/mine" "$H/.agents/skills" "$H/.claude/skills"
printf -- '---\nname: mine\ndescription: A skill the user keeps outside the hub.\n---\n' >"$H/personal/mine/SKILL.md"
ln -s "$H/personal/mine" "$H/.agents/skills/mine"
ln -s "$H/personal/mine" "$H/.claude/skills/mine"
run >/dev/null
expect "install leaves a working link the user made to the same skill" link_is "$H/.claude/skills/mine" "$H/personal/mine"
run --remove >/dev/null
expect "--remove keeps that working link the user made" link_is "$H/.claude/skills/mine" "$H/personal/mine"

fresh_home
mkdir -p "$H/.claude/skills"
ln -s "$repo/skills/coding-standards" "$H/.claude/skills/coding-standards"
run --remove >/dev/null
expect "--remove takes out a link shaped like the old installer's" absent "$H/.claude/skills/coding-standards"

fresh_home
mkdir -p "$H/.grok"
run >/dev/null
expect "install gives Grok Build links when it is installed" link_is "$H/.grok/skills/prune-tests" "$H/.agents/skills/prune-tests"

fresh_home
mkdir -p "$H/bin"
ln -s "$repo/install.sh" "$H/bin/install-skills"
expect "running through a link to the script exits 2" [ "$(status_of env HOME="$H" "$BASH" "$H/bin/install-skills")" = 2 ]
expect "running through a link to the script changes nothing" absent "$H/.agents"

rm -rf "${homes[@]}"
if [ "$failures" -gt 0 ]; then
  echo "$failures check(s) failed"
  exit 1
fi
echo "all checks passed"

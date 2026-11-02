#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
suite="$(mktemp -d "$repo/.test-sync.XXXXXX")"
trap 'rm -rf "$suite"' EXIT
failures=0
cases=0
real_node="$(command -v node)"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME='Sync tests' GIT_AUTHOR_EMAIL='sync@example.invalid'
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME" GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

git clone -q "$repo" "$suite/source"
git -C "$suite/source" checkout -q -B main
cp "$repo/sync" "$repo/sync.conf" "$repo/install.sh" "$suite/source/"
cp "$repo/config/models.md" "$suite/source/config/models.md"
cp "$repo/scripts/vendor-oracle-skill.sh" "$suite/source/scripts/vendor-oracle-skill.sh"
cp "$repo/skills/oracle/SKILL.md" "$repo/skills/oracle/LICENSE" "$suite/source/skills/oracle/"
git -C "$suite/source" add .
git -C "$suite/source" diff --cached --quiet || git -C "$suite/source" commit -qm 'Test current sync'
mkdir -p "$suite/ppt/skills/ppt-master"
printf 'presentation skill\n' >"$suite/ppt/skills/ppt-master/SKILL.md"
git -C "$suite/ppt" init -q
git -C "$suite/ppt" checkout -q -b main
git -C "$suite/ppt" add .
git -C "$suite/ppt" commit -qm 'Presentation fixture'
git clone -q --bare "$suite/ppt" "$suite/ppt.git"

cat >"$suite/fake" <<'SH'
#!/bin/bash
set -eu
tool="${0##*/}"
if [ "$tool" = node ]; then
  if [ "${1:-}" = --version ] && [ -n "${FAKE_NODE_VERSION:-}" ]; then echo "$FAKE_NODE_VERSION"; exit; fi
  exec "$REAL_NODE" "$@"
fi
printf '%s %s\n' "$tool" "$*" >>"$TEST_LOG"
case "$tool" in
  npx)
    if [ "${FAKE_NPX_FAIL:-0}" = 1 ]; then echo 'npx failed' >&2; exit 1; fi
    if [ "${FAKE_NPX_MALFORMED:-0}" = 1 ]; then echo '{bad json'; exit; fi
    if [ "$3" = update ] && [ "${FAKE_UPDATE_FAIL:-0}" = 1 ]; then exit 1; fi
    version="${FAKE_PSTACK_LATEST:-2.0.0-science.5}"
    case "$2" in *#v*) version="${2##*#v}" ;; esac
    if [ "$3" = update ]; then
      mkdir -p "$HOME/.fixture"
      echo "$version" >"$HOME/.fixture/pstack-version"
      source="$HOME/.claude/plugins/cache/t3-pstack-science/t3-pstack-science/$version/skills"
      case " $* " in *' --cursor '*) source="$HOME/.cursor/plugins/local/t3-pstack-science/skills" ;; esac
      for name in grill-me domain-modeling codebase-design improve-codebase-architecture wizard; do
        mkdir -p "$source/$name"
        echo "$name" >"$source/$name/SKILL.md"
      done
    fi
    have="${FAKE_PSTACK_VERSION:-}"
    if [ -z "$have" ] && [ -f "$HOME/.fixture/pstack-version" ]; then have="$(cat "$HOME/.fixture/pstack-version")"; fi
    ok=false; failed=1
    if [ "$have" = "$version" ]; then ok=true; failed=0; fi
    printf '{"version":"%s","homes":[{"harness":"claude","checks":[{"name":"installed","ok":%s,"detail":"%s"},{"name":"other plugins","ok":false,"warn":true,"detail":"Cursor account pstack shares names"}]}],"sheet":{"checks":[]},"failed":%s,"warnings":1}\n' "$version" "$ok" "${have:-missing}" "$failed"
    exit "$failed"
    ;;
  npm)
    if [ "$1" = prefix ]; then echo "$HOME/npm"; exit; fi
    mkdir -p "$HOME/.fixture"
    echo "${3##*@}" >"$HOME/.fixture/oracle-version"
    ;;
  oracle)
    if [ "${FAKE_ORACLE_BROKEN:-0}" = 1 ]; then exit 1; fi
    if [ -n "${FAKE_ORACLE_VERSION:-}" ]; then echo "oracle $FAKE_ORACLE_VERSION"
    elif [ -f "$HOME/.fixture/oracle-version" ]; then printf 'oracle '; cat "$HOME/.fixture/oracle-version"
    else echo 'oracle 0.0.0'
    fi
    ;;
  gh)
    if [ "$1" = repo ]; then
      git clone -q "$PPT_REMOTE" "$4"
      git -C "$4" remote set-url origin https://github.com/huankoh/ppt-master-white-sage.git
      git -C "$4" config "url.$PPT_REMOTE.insteadOf" https://github.com/huankoh/ppt-master-white-sage.git
      exit
    fi
    case "$2" in
      */commits/*) echo '1111111111111111111111111111111111111111' ;;
      */contents/skills/oracle/SKILL.md) echo 'verbatim updated Oracle skill' ;;
      */contents/LICENSE)
        if [ "${FAKE_VENDOR_FAIL:-0}" = 1 ]; then exit 1; fi
        echo 'verbatim updated license' ;;
      *) exit 1 ;;
    esac
    ;;
  mv)
    for backup in "$@"; do :; done
    printf 'backup that appeared during the move\n' >"$backup"
    exec /bin/mv "$@"
    ;;
  muse | gemini) ;;
  *) exit 1 ;;
esac
SH
chmod +x "$suite/fake"

fresh_home() {
  cases=$((cases + 1))
  case_dir="$suite/case-$cases"
  H="$case_dir/home"
  clone="$case_dir/repo"
  mkdir -p "$H" "$case_dir/bin"
  git clone -q "$suite/source" "$clone"
  for tool in npx npm oracle gh muse gemini node; do cp "$suite/fake" "$case_dir/bin/$tool"; done
  log="$case_dir/tools.log"
  output="$case_dir/output"
  : >"$log"
  extra=()
}

run() {
  status=0
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" PATH="$case_dir/bin:/usr/bin:/bin" \
    REAL_NODE="$real_node" TEST_LOG="$log" PPT_REMOTE="$suite/ppt.git" \
    ${extra[@]+"${extra[@]}"} "$BASH" "$clone/sync" "$@" >"$output" 2>&1 || status=$?
}

expect() {
  local label="$1"
  shift
  if "$@"; then echo "ok   $label"
  else
    echo "FAIL $label"
    cat "$output"
    failures=$((failures + 1))
  fi
}

link_is() { [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; }
absent() { [ ! -e "$1" ] && [ ! -L "$1" ]; }
no_installers() { ! grep -Eq '^npm install|^npx .* update |^gh repo clone' "$log"; }
snapshot() {
  local path
  while IFS= read -r path; do
    if [ -L "$path" ]; then printf '%s -> %s\n' "$path" "$(readlink "$path")"
    elif [ -f "$path" ]; then cksum "$path"
    else echo "$path/"
    fi
  # Fetch refreshes Git metadata even when all managed files already match.
  done < <(find "$H" -name .git -prune -o -print | LC_ALL=C sort)
}
no_backups() {
  local matches=("$1".bak-*)
  absent "${matches[0]}"
}
tools_present() {
  mkdir -p "$H/.cursor" "$H/.pi/agent" "$H/.config/opencode" \
    "$H/.t3/userdata/providers/antigravity/profile/antigravity-cli" \
    "$H/.t3/userdata/providers/antigravity/real/antigravity-cli/skills"
}
source_skills() {
  local name version="${1:-$pin}" config="${2:-$H/.claude}"
  source="$config/plugins/cache/t3-pstack-science/t3-pstack-science/$version/skills"
  for name in grill-me domain-modeling codebase-design improve-codebase-architecture wizard; do
    mkdir -p "$source/$name"
    echo "$name" >"$source/$name/SKILL.md"
  done
}

# shellcheck source=sync.conf
source "$repo/sync.conf"
pin=2.0.0-science.5

fresh_home
tools_present
mkdir -p "$H/.agents/skills/mine"
echo keep >"$H/.agents/skills/mine/SKILL.md"
run
expect 'fresh sync succeeds' [ "$status" = 0 ]
for name in coding-standards prune-tests oracle; do
  expect "hub links $name" link_is "$H/.agents/skills/$name" "$clone/skills/$name"
done
expect 'hub links the presentation skill' link_is "$H/.agents/skills/ppt-master" "$H/code/ppt-master-white-sage/skills/ppt-master"
expect 'Claude Code sees ppt-master on the first sync' link_is "$H/.claude/skills/ppt-master" "$H/.agents/skills/ppt-master"
expect 'Claude Code sees Oracle' link_is "$H/.claude/skills/oracle" "$H/.agents/skills/oracle"
expect 'Antigravity sees the hub' link_is "$H/.gemini/config/skills" "$H/.agents/skills"
expect 'user skills stay untouched' grep -qx keep "$H/.agents/skills/mine/SKILL.md"
expect 'model sheet links back into the clone' link_is "$H/.config/t3-pstack-science/models.md" "$clone/config/models.md"
source="$H/.cursor/plugins/local/t3-pstack-science/skills"
for target in "$H/.pi/agent/skills" "$H/.config/opencode/skills" "$H/.gemini/skills" \
  "$H/.gemini/antigravity-cli/skills" "$H/.t3/userdata/providers/antigravity/real/antigravity-cli/skills"; do
  expect "ported skills reach $target" link_is "$target/wizard" "$source/wizard"
done
expect 'T3 Antigravity profiles share the ported folder' link_is "$H/.t3/userdata/providers/antigravity/profile/antigravity-cli/skills" "$H/.gemini/antigravity-cli/skills"
expect 'ported skills never enter the hub' absent "$H/.agents/skills/wizard"
expect 'npm installs the exact Oracle pin' grep -qx "npm install -g @steipete/oracle@$ORACLE_VERSION" "$log"
expect 'pstack update gets the rolling channel and detected flags' grep -qx "npx -y github:huankoh/t3-pstack-science update --cursor --muse --json" "$log"
expect 'missing venv is reported' grep -q 'needs its skill venv' "$output"
expect 'missing browser profile prints the login command' grep -q 'oracle --engine browser --browser-manual-login --browser-keep-browser -p "HI"' "$output"
: >"$log"
before="$(snapshot)"
run
expect 'second sync succeeds' [ "$status" = 0 ]
expect 'second sync has no changed step' bash -c '! grep -Eq "^[^ ].* - changed" "$1"' _ "$output"
expect 'second sync runs no installer' no_installers
expect 'second sync preserves managed home contents' [ "$(snapshot)" = "$before" ]
: >"$log"
run --check
expect 'check passes after sync' [ "$status" = 0 ]
expect 'check after sync runs no installer' no_installers
expect 'check after sync preserves managed home contents' [ "$(snapshot)" = "$before" ]

fresh_home
tools_present
before="$(snapshot)"
run --check
expect 'fresh check exits 1' [ "$status" = 1 ]
expect 'fresh check changes no home contents' [ "$(snapshot)" = "$before" ]
expect 'fresh check runs no installer' no_installers
expect 'fresh check reports the missing clone' grep -q 'would change - clone' "$output"

fresh_home
mkdir -p "$H/.config/t3-pstack-science"
echo 'old model bytes' >"$H/.config/t3-pstack-science/models.md"
run
backups=("$H/.config/t3-pstack-science/"models.md.bak-*)
expect 'differing model sheet has one timestamped backup' [ "${#backups[@]}" = 1 ]
expect 'backup keeps the exact old bytes' grep -qx 'old model bytes' "${backups[0]}"
expect 'backup path has a UTC timestamp' bash -c '[[ "$1" =~ models.md.bak-[0-9]{8}T[0-9]{6}Z$ ]]' _ "${backups[0]}"
expect 'backup reports a diff command' grep -q 'diff -u' "$output"
expect 'differing model sheet becomes a link' link_is "$H/.config/t3-pstack-science/models.md" "$clone/config/models.md"

fresh_home
mkdir -p "$H/.config/t3-pstack-science"
echo 'original sheet before the race' >"$H/.config/t3-pstack-science/models.md"
cp "$suite/fake" "$case_dir/bin/mv"
run
backups=("$H/.config/t3-pstack-science/"models.md.bak-*)
expect 'a backup created during the move makes sync fail' [ "$status" = 1 ]
expect 'a raced backup is never overwritten' grep -qx 'backup that appeared during the move' "${backups[0]}"
expect 'a failed no-clobber move preserves the original sheet' grep -qx 'original sheet before the race' "$H/.config/t3-pstack-science/models.md"
expect 'a failed backup never replaces the sheet with a link' test ! -L "$H/.config/t3-pstack-science/models.md"
expect 'a backup race is reported in the model sheet step' grep -q '^model sheet - failed' "$output"
expect 'a backup race still allows later steps to run' grep -q '^npm install ' "$log"

fresh_home
mkdir -p "$H/.config/t3-pstack-science"
cp "$clone/config/models.md" "$H/.config/t3-pstack-science/models.md"
run
expect 'identical model sheet becomes a link' link_is "$H/.config/t3-pstack-science/models.md" "$clone/config/models.md"
expect 'identical model sheet needs no backup' no_backups "$H/.config/t3-pstack-science/models.md"
expect 'identical model sheet reports no backup' bash -c '! grep -q "backing up" "$1"' _ "$output"

fresh_home
tools_present
mkdir -p "$H/.pi/agent/skills/wizard" "$H/.agents/skills/ppt-master"
echo keep-wizard >"$H/.pi/agent/skills/wizard/SKILL.md"
echo keep-ppt >"$H/.agents/skills/ppt-master/SKILL.md"
run
expect 'conflicting real folders make sync fail' [ "$status" = 1 ]
expect 'real ported-skill folder is preserved' grep -qx keep-wizard "$H/.pi/agent/skills/wizard/SKILL.md"
expect 'real presentation folder is preserved' grep -qx keep-ppt "$H/.agents/skills/ppt-master/SKILL.md"
expect 'ported conflict is reported' grep -q 'left .*skills/wizard untouched' "$output"
expect 'presentation conflict is reported' grep -q 'left .*skills/ppt-master untouched' "$output"

fresh_home
mkdir -p "$H/code"
git clone -q "$suite/ppt.git" "$H/code/ppt-master-white-sage"
git -C "$H/code/ppt-master-white-sage" remote set-url origin https://github.com/huankoh/ppt-master-white-sage.git
git -C "$H/code/ppt-master-white-sage" config "url.$suite/ppt.git.insteadOf" https://github.com/huankoh/ppt-master-white-sage.git
git -C "$H/code/ppt-master-white-sage" checkout -q -b venv-path-through-links
ppt_head="$(git -C "$H/code/ppt-master-white-sage" rev-parse HEAD)"
run
expect 'presentation feature branch is accepted' [ "$status" = 0 ]
expect 'presentation branch is reported' grep -q 'is on venv-path-through-links; pull skipped' "$output"
expect 'presentation feature branch is not pulled' [ "$(git -C "$H/code/ppt-master-white-sage" rev-parse HEAD)" = "$ppt_head" ]
expect 'presentation branch still gets its link' test -f "$H/.claude/skills/ppt-master/SKILL.md"

for origin in https://github.com/huankoh/ppt-master-white-sage https://github.com/huankoh/ppt-master-white-sage.git \
  ssh://git@github.com/huankoh/ppt-master-white-sage ssh://git@github.com/huankoh/ppt-master-white-sage.git \
  git@github.com:huankoh/ppt-master-white-sage git@github.com:huankoh/ppt-master-white-sage.git; do
  fresh_home
  directory="$H/code/ppt-master-white-sage"
  git clone -q "$suite/ppt.git" "$directory"
  git -C "$directory" remote set-url origin "$origin"
  git -C "$directory" config "url.$suite/ppt.git.insteadOf" "$origin"
  run
  expect "presentation origin accepts $origin" [ "$status" = 0 ]
  expect 'a matching origin gets its skill link' link_is "$H/.agents/skills/ppt-master" "$directory/skills/ppt-master"
done

fresh_home
directory="$H/code/ppt-master-white-sage"
git clone -q "$suite/ppt.git" "$directory"
git -C "$directory" remote set-url origin https://github.com/someone/other-project.git
git -C "$directory" config "url.$suite/ppt.git.insteadOf" https://github.com/someone/other-project.git
run
expect 'an unrelated presentation origin fails' [ "$status" = 1 ]
expect 'an unrelated presentation origin is reported' grep -q '^ppt-master - failed - .*origin.*does not name' "$output"
expect 'an unrelated presentation clone is not pulled' absent "$directory/.git/FETCH_HEAD"
expect 'an unrelated presentation skill is never linked' absent "$H/.agents/skills/ppt-master"
run --check
expect 'check rejects an unrelated presentation origin' grep -q '^ppt-master - failed - .*origin.*does not name' "$output"
expect 'check does not fetch an unrelated presentation clone' absent "$directory/.git/FETCH_HEAD"

fresh_home
source_skills
extra=("FAKE_PSTACK_VERSION=$pin" "FAKE_ORACLE_VERSION=$ORACLE_VERSION")
run
expect 'matching versions succeed despite the expected warning' [ "$status" = 0 ]
expect 'matching pstack version runs no update' bash -c '! grep -q "npx .* update " "$1"' _ "$log"
expect 'matching Oracle version runs no npm' bash -c '! grep -q "^npm " "$1"' _ "$log"

fresh_home
source_skills 2.1.0
extra=(FAKE_PSTACK_LATEST=2.1.0 FAKE_PSTACK_VERSION=2.1.0)
run
expect 'a newer rolling release passes doctor without reinstalling' [ "$status" = 0 ]
expect 'a newer rolling release runs no updater' bash -c '! grep -q "npx .* update " "$1"' _ "$log"
expect 'doctor follows the marketplaces rolling channel' grep -qx 'npx -y github:huankoh/t3-pstack-science doctor --muse --json' "$log"

fresh_home
mkdir -p "$H/.fixture"
echo older >"$H/.fixture/pstack-version"
run
expect 'a behind home gets exactly one pstack update' [ "$(grep -c 'npx .* update ' "$log")" = 1 ]

fresh_home
extra=(FAKE_NPX_FAIL=1)
run
expect 'a broken doctor makes sync fail' [ "$status" = 1 ]
expect 'a broken doctor does not attempt an update' bash -c '! grep -q "npx .* update " "$1"' _ "$log"
expect 'later Oracle step runs after a pstack failure' grep -q '^npm install ' "$log"
expect 'summary includes the pstack failure' grep -q '^pstack - failed' "$output"

fresh_home
extra=(FAKE_NPX_MALFORMED=1)
run
expect 'malformed doctor JSON makes sync fail' [ "$status" = 1 ]
expect 'malformed doctor JSON never triggers an updater' bash -c '! grep -q "npx .* update " "$1"' _ "$log"

fresh_home
extra=(FAKE_UPDATE_FAIL=1)
run
expect 'a failed pstack update makes sync fail' [ "$status" = 1 ]
expect 'later Oracle step runs after update failure' grep -q '^npm install ' "$log"

fresh_home
extra=(FAKE_ORACLE_BROKEN=1)
run
expect 'a stale Oracle shim makes sync fail' [ "$status" = 1 ]
expect 'stale Oracle shim is reported by path' grep -q "Oracle at $case_dir/bin/oracle shadows npm global bin" "$output"
expect 'stale Oracle shim stays untouched' cmp -s "$suite/fake" "$case_dir/bin/oracle"

fresh_home
extra=(FAKE_NODE_VERSION=v22.0.0)
mkdir -p "$H/.nvm/versions/node/v24.2.0/bin" "$H/.nvm/versions/node/v24.22.0/bin"
for version in 24.2.0 24.22.0; do
  printf '#!/bin/bash\nif [ "${1:-}" = --version ]; then echo v%s; else exec "%s" "$@"; fi\n' "$version" "$real_node" >"$H/.nvm/versions/node/v$version/bin/node"
  chmod +x "$H/.nvm/versions/node/v$version/bin/node"
done
run
expect 'an older PATH Node falls back to nvm' [ "$status" = 0 ]
expect 'nvm selection uses numeric version ordering' grep -q '^node - already right - using .*v24.22.0/bin' "$output"

fresh_home
extra=(FAKE_NODE_VERSION=v22.0.0)
run
expect 'missing modern Node skips dependent steps' grep -q '^pstack - skipped - pstack needs Node 24+' "$output"
expect 'missing modern Node skips Oracle' grep -q '^oracle - skipped - Oracle needs Node 24+' "$output"
expect 'missing modern Node runs no Node installer' bash -c '! grep -Eq "^npm install|^npx " "$1"' _ "$log"
expect 'missing modern Node still links skills' test -f "$H/.agents/skills/oracle/SKILL.md"

fresh_home
mkdir -p "$H/.pi/agent"
source_skills
extra=("FAKE_PSTACK_VERSION=$pin")
run
expect 'ported skills fall back to Claude Code cache' link_is "$H/.pi/agent/skills/wizard" "$source/wizard"
mkdir -p "$H/.cursor/plugins/local/t3-pstack-science/skills"
cp -R "$source/." "$H/.cursor/plugins/local/t3-pstack-science/skills/"
run
expect 'an owned ported link moves to the Cursor source' link_is "$H/.pi/agent/skills/wizard" "$H/.cursor/plugins/local/t3-pstack-science/skills/wizard"

fresh_home
mkdir -p "$H/.pi/agent"
source_skills 2.9.0
source_skills 2.10.0-science.9
source_skills 2.10.0-science.12
newest_source="$source"
extra=("FAKE_PSTACK_VERSION=$pin")
run
expect 'ported source uses the numerically highest Claude cache' link_is "$H/.pi/agent/skills/wizard" "$newest_source/wizard"
source_skills 2.10.0
run
expect 'a stable cache release sorts after its prereleases' link_is "$H/.pi/agent/skills/wizard" "$source/wizard"

fresh_home
mkdir -p "$H/.pi/agent"
source_skills 3.0.0 "$H/claude-config"
extra=("FAKE_PSTACK_VERSION=$pin" "CLAUDE_CONFIG_DIR=$H/claude-config")
run
expect 'ported source falls back to CLAUDE_CONFIG_DIR' link_is "$H/.pi/agent/skills/wizard" "$source/wizard"
source_skills
run
expect 'the default Claude cache precedes CLAUDE_CONFIG_DIR' link_is "$H/.pi/agent/skills/wizard" "$source/wizard"

fresh_home
mkdir -p "$H/.pi/agent"
extra=("FAKE_PSTACK_VERSION=$pin")
run
expect 'a present destination without a source fails' [ "$status" = 1 ]
expect 'a missing ported source is reported as failed' grep -q '^ported skills - failed - no pstack skills source' "$output"
expect 'a missing source creates no ported folder' absent "$H/.pi/agent/skills"
rm "$case_dir/bin/gemini"
rmdir "$H/.pi/agent"
run
expect 'no destination tool permits the ported step to skip' grep -q '^ported skills - skipped - no destination tools' "$output"

fresh_home
mkdir -p "$H/.agents/skills/nested" "$H/.pi/agent" "$H/.config/opencode"
ln -s "$H/.agents/skills" "$H/.pi/agent/skills"
ln -s "$H/.agents/skills/nested" "$H/.config/opencode/skills"
source_skills
run --check
expect 'check rejects ported folders linked into the hub' grep -q '^ported skills - failed - .*resolves into the skills hub' "$output"
expect 'check puts no ported skill in the hub' absent "$H/.agents/skills/wizard"
run
expect 'ported folders linked into the hub make sync fail' [ "$status" = 1 ]
expect 'a direct hub alias receives no ported skill' absent "$H/.agents/skills/wizard"
expect 'a hub descendant receives no ported skill' absent "$H/.agents/skills/nested/wizard"
expect 'the direct hub alias remains untouched' link_is "$H/.pi/agent/skills" "$H/.agents/skills"

fresh_home
mkdir -p "$H/.agents/skills" "$H/.pi" "$H/.t3/userdata/providers/antigravity/profile"
ln -s "$H/.agents/skills" "$H/.pi/agent"
ln -s "$H/.agents/skills" "$H/.t3/userdata/providers/antigravity/profile/antigravity-cli"
run
expect 'a missing folder under a hub alias makes sync fail' [ "$status" = 1 ]
expect 'a linked ancestor never receives a new ported folder' absent "$H/.agents/skills/skills"
expect 'a linked T3 profile ancestor is reported' grep -q 'antigravity/profile/antigravity-cli/skills resolves into the skills hub' "$output"

fresh_home
mkdir -p "$H/shared-agents/skills/nested" "$H/.pi/agent"
ln -s "$H/shared-agents" "$H/.agents"
ln -s "$H/shared-agents/skills/nested" "$H/.pi/agent/skills"
run
expect 'hub protection resolves the hub itself through aliases' [ "$status" = 1 ]
expect 'a physical hub descendant receives no ported skill' absent "$H/shared-agents/skills/nested/wizard"

fresh_home
mkdir -p "$H/.pi/agent/skills" "$H/personal/wizard"
echo keep >"$H/personal/wizard/SKILL.md"
ln -s "$H/personal/wizard" "$H/.pi/agent/skills/wizard"
run
expect 'an unrelated ported-skill link is a conflict' [ "$status" = 1 ]
expect 'an unrelated ported-skill link stays untouched' link_is "$H/.pi/agent/skills/wizard" "$H/personal/wizard"

fresh_home
rm "$case_dir/bin/muse"
run
expect 'pstack omits flags for absent optional tools' grep -qx "npx -y github:huankoh/t3-pstack-science update --json" "$log"

fresh_home
mkdir -p "$H/.config/t3-pstack-science" "$H/old-sheet"
echo 'linked old sheet' >"$H/old-sheet/models.md"
ln -s "$H/old-sheet/models.md" "$H/.config/t3-pstack-science/models.md"
run
backups=("$H/.config/t3-pstack-science/"models.md.bak-*)
expect 'a foreign sheet link is backed up as a link' link_is "${backups[0]}" "$H/old-sheet/models.md"
expect 'a foreign sheet link target stays untouched' grep -qx 'linked old sheet' "$H/old-sheet/models.md"

fresh_home
extra=("XDG_CONFIG_HOME=$H/settings")
run
expect 'model sheet respects XDG_CONFIG_HOME' link_is "$H/settings/t3-pstack-science/models.md" "$clone/config/models.md"

fresh_home
git -C "$clone" checkout -q -b work
run
expect 'sync repo feature branch is reported' grep -q '^repo - skipped - .* is on work; pull skipped' "$output"
fresh_home
echo dirty >>"$clone/README.md"
run
expect 'sync repo dirty tree is reported' grep -q '^repo - skipped - .* has a dirty tree; pull skipped' "$output"

fresh_home
printf '\n# updated fixture\n' >>"$suite/source/sync"
git -C "$suite/source" add sync
git -C "$suite/source" commit -qm 'Update sync fixture'
source_skills
extra=("FAKE_PSTACK_VERSION=$pin" "FAKE_ORACLE_VERSION=$ORACLE_VERSION")
run --check
expect 'repo check reports behind commits' grep -q 'is 1 commits behind' "$output"
expect 'repo check preserves the checkout' bash -c '! grep -q "updated fixture" "$1"' _ "$clone/sync"
: >"$log"
run
expect 'repo pull restarts an updated sync once' [ "$(grep -c 'sync updated itself; restarting once' "$output")" = 1 ]
expect 'repo pull gets the updated script' grep -q 'updated fixture' "$clone/sync"
expect 'restarted sync completes' [ "$status" = 0 ]

fresh_home
source_skills
mkdir -p "$source/setup-pstack/scripts"
cat >"$source/setup-pstack/scripts/t3-sheet.mjs" <<'JS'
export const parseSheet = text => text;
export const checkSheet = text => text.includes('INVALID') ? ['invalid sheet'] : [];
JS
echo '{}' >"$source/../models.json"
extra=("FAKE_PSTACK_VERSION=$pin")
run
expect 'model sheet uses the installed offline validator' grep -q 'model sheet validation passed' "$output"
echo INVALID >>"$clone/config/models.md"
run
expect 'invalid model sheet fails its step' grep -q '^model sheet - failed' "$output"
expect 'invalid model sheet makes sync exit 1' [ "$status" = 1 ]

fresh_home
env HOME="$H" PATH="$case_dir/bin:/usr/bin:/bin" TEST_LOG="$log" \
  "$BASH" "$clone/scripts/vendor-oracle-skill.sh" topic/test >"$output" 2>&1
expect 'vendor updater records the resolved commit' grep -qx 'ORACLE_SKILL_COMMIT=1111111111111111111111111111111111111111' "$clone/sync.conf"
expect 'vendor updater preserves upstream skill bytes' grep -qx 'verbatim updated Oracle skill' "$clone/skills/oracle/SKILL.md"
expect 'vendor updater preserves upstream license bytes' grep -qx 'verbatim updated license' "$clone/skills/oracle/LICENSE"
expect 'vendor updater fetches both files at the resolved commit' [ "$(grep -c 'ref=1111111111111111111111111111111111111111' "$log")" = 2 ]
before="$(cksum "$clone/sync.conf" "$clone/skills/oracle/SKILL.md" "$clone/skills/oracle/LICENSE")"
status=0
env HOME="$H" PATH="$case_dir/bin:/usr/bin:/bin" TEST_LOG="$log" FAKE_VENDOR_FAIL=1 \
  "$BASH" "$clone/scripts/vendor-oracle-skill.sh" >"$output" 2>&1 || status=$?
expect 'vendor download failure exits 1' [ "$status" = 1 ]
expect 'vendor download failure preserves tracked bytes' [ "$(cksum "$clone/sync.conf" "$clone/skills/oracle/SKILL.md" "$clone/skills/oracle/LICENSE")" = "$before" ]

mkdir -p "$suite/install-tmp"
status=0
TMPDIR="$suite/install-tmp" "$BASH" "$repo/checks/test_install.sh" >"$output" 2>&1 || status=$?
expect 'existing installer suite still passes' [ "$status" = 0 ]

if [ "$failures" -gt 0 ]; then echo "$failures check(s) failed"; exit 1; fi
echo "all sync checks passed ($cases isolated homes)"

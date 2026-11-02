#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
if [ "$#" -gt 1 ]; then
  echo "usage: vendor-oracle-skill.sh [ref]" >&2
  exit 2
fi
# shellcheck source=sync.conf
source "$repo/sync.conf"
ref="${1:-main}"
commit="$(gh api "repos/$ORACLE_SKILL_REPO/commits/$ref" --jq .sha)"
if [[ ! "$commit" =~ ^[0-9a-f]{40}$ ]]; then
  echo "GitHub did not resolve $ref to a full commit" >&2
  exit 1
fi

stage="$(mktemp -d "$repo/.vendor-oracle.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
for path in skills/oracle/SKILL.md LICENSE; do
  gh api "repos/$ORACLE_SKILL_REPO/contents/$path" --method GET \
    -H 'Accept: application/vnd.github.raw+json' -f "ref=$commit" >"$stage/$(basename "$path")"
  test -s "$stage/$(basename "$path")"
done
sed "s/^ORACLE_SKILL_COMMIT=.*/ORACLE_SKILL_COMMIT=$commit/" "$repo/sync.conf" >"$stage/sync.conf"
mkdir -p "$repo/skills/oracle"
mv "$stage/SKILL.md" "$stage/LICENSE" "$repo/skills/oracle/"
mv "$stage/sync.conf" "$repo/sync.conf"
echo "vendored $ORACLE_SKILL_REPO at $commit; review the diff before committing"

#!/usr/bin/env bash
# Rebuilds the Multica-importable mirror from an upstream agency-agents checkout.
#
# Usage: build-mirror.sh <upstream-dir> <mirror-root>
#
# Upstream layout:  <division>/<persona>.md      (each with name/description frontmatter)
# Mirror layout:    skills/<division>/<persona>/SKILL.md
#                   -> importable via github.com/<user>/<repo>/blob/main/skills/<division>/<persona>/SKILL.md
#                      (Multica import requires the file to be named SKILL.md)
#
# Non-persona files skipped:
#   integrations/, examples/, scripts/, docs/, .github/, READMEs
#   strategy/EXECUTIVE-BRIEF.md, strategy/nexus-strategy.md, strategy/QUICKSTART.md (no frontmatter)
set -euo pipefail

SRC="$(realpath "${1:?usage: build-mirror.sh <upstream-dir> <mirror-root>}")"
ROOT="$(realpath -m "${2:?usage: build-mirror.sh <upstream-dir> <mirror-root>}")"
OUT="$ROOT/skills"
[ -d "$SRC" ] || { cd /; echo "upstream dir not found: $SRC" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT"

cd "$SRC"
count=0
for f in */*.md; do
  div="${f%%/*}"
  base="$(basename "$f" .md)"
  case "$div" in
    integrations|examples|scripts|docs|.github) continue ;;
  esac
  case "$base" in
    EXECUTIVE-BRIEF|nexus-strategy|QUICKSTART) continue ;;
  esac
  # Only accept files that carry skill frontmatter (safety guard for new doc files)
  first_line=$(head -n 1 "$f")
  if [ "$first_line" != "---" ]; then
    echo "skip (no frontmatter): $f" >&2
    continue
  fi
  mkdir -p "$OUT/$div/$base"
  cp "$f" "$OUT/$div/$base/SKILL.md"
  count=$((count + 1))
done

echo "mirror rebuilt: $count personas under $OUT"

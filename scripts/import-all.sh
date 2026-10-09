#!/usr/bin/env bash
# Importa todas as personas do espelho no Multica.
# - le origem de /tmp/all-skills-paths.txt (gerado do tree do repo local)
# - gera URL blob/main/<pasta>/SKILL.md e chama multica skill import
# - idempotente: --on-conflict skip pula as que ja existem
# - registra resultado por skill em /tmp/import-results.tsv
set -uo pipefail

REPO="raphaelwdrf/agency-agents-to-multica"
BRANCH="main"
PATHS_FILE="${1:-/tmp/all-skills-paths.txt}"
RESULTS="${2:-/tmp/import-results.tsv}"

: > "$RESULTS"
total=$(grep -c SKILL.md "$PATHS_FILE")
n=0
ok=0
skip=0
fail=0

while IFS= read -r p; do
  url="https://github.com/${REPO}/blob/${BRANCH}/${p}"
  n=$((n + 1))
  resp=$(multica skill import --url "$url" --on-conflict skip --output json 2>&1)
  if echo "$resp" | grep -q '"id"'; then
    sid=$(echo "$resp" | grep -m1 -o '"id": *"[a-f0-9-]*"' | cut -d'"' -f4)
    sname=$(echo "$resp" | grep -m1 -o '"name": *"[^"]*"' | cut -d'"' -f4)
    printf '%s\t%s\t%s\n' "$sid" "$sname" "$p" >> "$RESULTS"
    ok=$((ok + 1))
  elif echo "$resp" | grep -q -i 'already\|exist\|skip'; then
    skip=$((skip + 1))
    printf 'SKIP\t-\t%s\n' "$p" >> "$RESULTS"
  else
    fail=$((fail + 1))
    printf 'FAIL\t(%s)\t%s\n' "$(echo "$resp" | head -c 120)" "$p" >> "$RESULTS"
  fi
  if [ $((n % 25)) -eq 0 ]; then
    echo "progresso: $n/$total (ok=$ok skip=$skip fail=$fail)"
  fi
done < "$PATHS_FILE"

echo "FINITO: total=$total ok=$ok skip=$skip fail=$fail"

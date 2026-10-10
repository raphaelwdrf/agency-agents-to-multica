#!/usr/bin/env bash
# Cria 1 agent Multica por skill do roster Agency, segundo a receita do usuário:
#   name          = exatamente o name do frontmatter da skill
#   description   = "" (vazio)
#   instructions  = 1 frase: sempre processar a skill antes de começar
#   model         = deepseek-v4.1-flash (Agency Orchestrator fica com glm-5.3-flash, já setado)
#   thinking      = vazio (default do runtime Hermes)
#   skills        = 1 devido
# Idempotente: skip se o agent já existe (checa por nome).
# Registra id↔skill em /tmp/agents-created.tsv
set -uo pipefail

RH="8a5cd284-c696-4339-8887-60911f4476dd"   # Hermes (vpsrwdrf)
MODEL="deepseek-v4.1-flash"
RESULTS="${1:-/tmp/agents-created.tsv}"

# import-results.tsv: id\tname\tpath
INFILE=/tmp/import-results.tsv
total=$(grep -c $'^[0-9a-f]' "$INFILE")
ok=0; skip=0; fail=0
n=0

while IFS=$'\t' read -r sid sname spath; do
  n=$((n + 1))
  # pula quem não tem id de skill (linhas SKIP/FAIL)
  case "$sid" in
    [0-9a-f]*-*) : ;;
    *) continue ;;
  esac
  # idempotência: agent com mesmo nome?
  existing=$(multica agent list --output json 2>/dev/null | grep -F "\"name\": \"$sname\"" | wc -l)
  if [ "$existing" != "0" ]; then
    skip=$((skip + 1))
    printf 'SKIP\t%s\t%s\n' "$sname" "$sid" >> "$RESULTS"
    continue
  fi
  resp=$(multica agent create \
    --name "$sname" \
    --runtime-id "$RH" \
    --model "$MODEL" \
    --instructions "Your full persona, methodology and deliverables live in your assigned skill \"$sname\". Always read and process that skill BEFORE starting any task — it is the single source of truth for how you work." \
    --output json 2>&1)
  aid=$(echo "$resp" | grep -m1 -o '"id": *"[a-f0-9-]*"' | cut -d'"' -f4)
  if [ -n "$aid" ]; then
    ls2=$(multica agent skills add "$aid" --skill-ids "$sid" --output json 2>&1 | grep -c '"id"')
    if [ "$ls2" -gt 0 ]; then
      ok=$((ok + 1))
      printf '%s\t%s\t%s\n' "$aid" "$sname" "$sid" >> "$RESULTS"
    else
      fail=$((fail + 1))
      printf 'FAIL-LINK\t%s\t%s\n' "$sname" "$sid" >> "$RESULTS"
    fi
  else
    fail=$((fail + 1))
    printf 'FAIL-CREATE\t(%s)\t%s\n' "$(echo "$resp" | head -c 100)" "$sname" >> "$RESULTS"
  fi
  if [ $((n % 30)) -eq 0 ]; then
    echo "progresso: $n/$total (ok=$ok skip=$skip fail=$fail)"
  fi
done < "$INFILE"

echo "FINITO: total=$total ok=$ok skip=$skip fail=$fail (mais o Agency Orchestrator pre-criado)"

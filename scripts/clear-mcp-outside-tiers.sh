#!/usr/bin/env bash
# Limpa mcp_config de todos os agents FORA dos tiers 1/2/3 (que devem manter
# deepwiki + gh_grep + context7).
set -uo pipefail
TIER_FILE="${1:?usage: clear-mcp-outside-tiers.sh <tier-slugs.txt>}"

# nomes de skills nos tiers -> nome exato do agent (name: do frontmatter)
ok=0; skip=0; fail=0
multica agent list --output json 2>/dev/null | python3 -c "
import json,sys
ags=[a for a in json.load(sys.stdin) if not a.get('archived_at')]
tiers=[l.strip() for l in open('$TIER_FILE') if l.strip()]
keep=[]
for a in ags:
    skills=[s['name'] for s in a.get('skills',[])]
    if skills and skills[0] in tiers: keep.append(a['id'])
import sys as s
s.stderr.write(f'agents nos tiers: {len(keep)}\n')
for a in ags:
    if a['id'] not in keep:
        print(a['id'])
" > /tmp/clear-mcp-ids.txt
n=$(wc -l < /tmp/clear-mcp-ids.txt)
echo "agents a limpar: $n"
for id in $(cat /tmp/clear-mcp-ids.txt); do
  multica agent update "$id" --mcp-config '{}' --output json >/dev/null 2>&1
  ok=$((ok+1))
  [ $((ok % 60)) -eq 0 ] && echo "... $ok limpos"
done
echo "limpos: $ok"

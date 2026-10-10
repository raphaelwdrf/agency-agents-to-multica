#!/usr/bin/env bash
# Add all 267 Agency agents as members of the "Agency" squad.
# Leader (Orchestrator) auto-included by the platform on creation.
# Idempotent: skip agents already in the member list.
set -uo pipefail
SQID="${1:?usage: add-squad-members.sh <squad-id>}"
ALREADY=$(mktemp)
multica squad member list "$SQID" --output json 2>/dev/null | python3 -c "
import json,sys
try: ms=json.load(sys.stdin)
except: ms=[]
for m in ms: print(m.get('id') or m.get('member_id') or '')
" > "$ALREADY"
n=$(wc -l < "$ALREADY")
ok=0; skip=0; fail=0
multica agent list --output json 2>/dev/null | python3 -c "
import json,sys
ags=json.load(sys.stdin)
for a in ags:
    if not a.get('archived_at'):
        print(a['id']+'\t'+a['name'])
" | while IFS=$'\t' read -r aid aname; do
  if grep -q "^$aid\$" "$ALREADY"; then
    skip=$((skip+1))
    continue
  fi
  resp=$(multica squad member add "$SQID" --member-id "$aid" --type agent --role "Agency specialist: $aname" --output json 2>&1)
  if echo "$resp" | grep -q '"id"\|"member"'; then
    ok=$((ok+1))
  else
    fail=$((fail+1))
    echo "FAIL: $aname -> $(echo "$resp" | head -c 100)"
  fi
  total=$((ok+skip+fail))
  [ $((total % 40)) -eq 0 ] && echo "progresso: $total (ok=$ok skip=$skip fail=$fail)"
done
echo "FINITO: ok=$ok skip=$skip fail=$fail"

#!/bin/bash
set -euo pipefail
mkdir -p /logs/verifier
APP=/app/reconcile.py
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

check_cli=0
check_logic=0
check_edge=0

cat > "$TMP/logic.csv" <<'CSV'
tx_id,timestamp,amount,status
v1,2026-01-01T10:00:00Z,100.00,SUCCESS
f1,2026-01-01T11:00:00Z,50.00,FAILED
p1,2026-01-01T12:00:00Z,999.00,PENDING
CSV

if python "$APP" "$TMP/logic.csv" > "$TMP/out.json" 2>/dev/null; then
  check_cli=1
  python - "$TMP/out.json" <<'PY' && check_logic=1 || true
import json,sys
v=json.load(open(sys.argv[1]))
assert v["valid_count"] == 1
assert v["failed_count"] == 1
assert v["total_valid_amount"] == 100.0
PY
fi

cat > "$TMP/edge.csv" <<'CSV'
tx_id,timestamp,amount,status
dup,2026-01-01T10:00:00-05:00,10.00,SUCCESS
dup,2026-01-01T14:00:00Z,20.00,FAILED
ok,2026-01-01T15:00:00Z,3.25,SUCCESS
CSV
if python "$APP" "$TMP/edge.csv" > "$TMP/edge.json" 2>/dev/null; then
  python - "$TMP/edge.json" <<'PY' && check_edge=1 || true
import json,sys
v=json.load(open(sys.argv[1]))
assert v["valid_count"] == 2
assert v["failed_count"] == 0
assert v["total_valid_amount"] == 13.25
PY
fi

score="$(python - "$check_cli" "$check_logic" "$check_edge" <<'PY'
import sys
checks=list(map(int,sys.argv[1:]))
print(f"{sum(w*c for w,c in zip((0.20,0.30,0.50),checks)):.3f}")
PY
)"
printf '%s\n' "$score" > /logs/verifier/reward.txt

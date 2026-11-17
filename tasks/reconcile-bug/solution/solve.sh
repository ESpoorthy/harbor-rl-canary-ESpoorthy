#!/bin/bash
set -euo pipefail
cat > /app/reconcile.py <<'PY'
#!/usr/bin/env python3
import argparse
import csv
import json
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation


def parse_instant(value):
    text = (value or "").strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    parsed = datetime.fromisoformat(text)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def reconcile(path):
    latest = {}
    with open(path, newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            tx_id = (row.get("tx_id") or "").strip()
            if not tx_id:
                continue
            try:
                stamp = parse_instant(row.get("timestamp"))
                amount = Decimal((row.get("amount") or "").strip())
                if not amount.is_finite():
                    continue
            except (ValueError, TypeError, InvalidOperation):
                continue
            candidate = (stamp, row, amount)
            if tx_id not in latest or stamp > latest[tx_id][0]:
                latest[tx_id] = candidate

    valid_total = Decimal("0.00")
    valid_count = 0
    failed_count = 0
    for _, row, amount in latest.values():
        status = (row.get("status") or "").strip().upper()
        if status == "SUCCESS":
            valid_total += amount
            valid_count += 1
        elif status == "FAILED":
            failed_count += 1

    return {
        "total_valid_amount": float(valid_total.quantize(Decimal("0.01"))),
        "valid_count": valid_count,
        "failed_count": failed_count,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path")
    args = parser.parse_args()
    print(json.dumps(reconcile(args.csv_path)))


if __name__ == "__main__":
    main()
PY
chmod +x /app/reconcile.py

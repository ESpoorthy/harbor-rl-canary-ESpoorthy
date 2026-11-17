#!/usr/bin/env python3
"""Intentionally defective starter implementation for the Harbor task.

The three deliberate defects are in CLI handling, status/amount logic, and
duplicate timestamp ordering. This file is the agent's starting point.
"""
import argparse
import csv
import json
from decimal import Decimal


def reconcile(path):
    valid_total = Decimal("0.00")
    valid_count = 0
    failed_count = 0
    seen = {}

    with open(path, newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            tx_id = (row.get("tx_id") or "").strip()
            if not tx_id:
                continue
            # Defect 3: compares timestamp strings, not timezone-normalized instants.
            timestamp = (row.get("timestamp") or "").strip()
            if tx_id in seen and timestamp <= seen[tx_id]:
                continue
            seen[tx_id] = timestamp

            status = (row.get("status") or "").strip().upper()
            try:
                amount = Decimal((row.get("amount") or "").strip())
            except Exception:
                continue

            # Defect 2: PENDING rows are incorrectly counted as valid.
            if status in ("SUCCESS", "PENDING"):
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
    # Defect 1: required flag is not documented in the task's expected invocation.
    parser.add_argument("--input", required=True, help="input CSV path")
    args = parser.parse_args()
    print(json.dumps(reconcile(args.input)))


if __name__ == "__main__":
    main()

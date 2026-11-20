#!/usr/bin/env bash
set -u

mkdir -p /logs/verifier

python3 - <<'PY'
import csv
import json
import random
import subprocess
import tempfile
from decimal import Decimal
from pathlib import Path

WEIGHT_CLI = Decimal("0.20")
WEIGHT_LOGIC = Decimal("0.30")
WEIGHT_EDGE = Decimal("0.50")


def run_reconcile(csv_path: Path):
    proc = subprocess.run(
        ["python3", "/app/reconcile.py", str(csv_path)],
        capture_output=True,
        text=True,
        timeout=15,
    )
    if proc.returncode != 0:
        return None
    try:
        data = json.loads(proc.stdout.strip())
    except Exception:
        return None
    expected_keys = {"total_valid_amount", "valid_count", "failed_count"}
    if not isinstance(data, dict) or set(data.keys()) != expected_keys:
        return None
    return data


def check_cli(tmpdir: Path) -> bool:
    # Randomized single-batch CSV so hardcoded JSON outputs cannot pass
    a1 = Decimal(random.randint(10, 99)) + Decimal("0.25")
    a2 = Decimal(random.randint(100, 299)) + Decimal("0.50")
    a3 = Decimal(random.randint(5, 45)) + Decimal("0.10")

    csv_path = tmpdir / "cli_rand.csv"
    with csv_path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["tx_id", "timestamp", "amount", "status"])
        w.writerow(["tx_c1", "2026-01-10T10:00:00Z", f"{a1:.2f}", "SUCCESS"])
        w.writerow(["tx_c2", "2026-01-10T11:00:00Z", f"{a2:.2f}", "SUCCESS"])
        w.writerow(["tx_c3", "2026-01-10T12:00:00Z", f"{a3:.2f}", "FAILED"])

    res = run_reconcile(csv_path)
    if res is None:
        return False

    expected_total = float(a1 + a2)
    return (
        abs(float(res["total_valid_amount"]) - expected_total) < 1e-6
        and res["valid_count"] == 2
        and res["failed_count"] == 1
    )


def check_logic(tmpdir: Path) -> bool:
    # Randomized SUCCESS, FAILED, PENDING, and malformed rows
    s_vals = [Decimal(random.randint(20, 150)) + Decimal("0.33") for _ in range(3)]
    p_val = Decimal(random.randint(50, 200)) + Decimal("0.75")
    f_vals = [Decimal(random.randint(10, 80)) + Decimal("0.15") for _ in range(2)]

    csv_path = tmpdir / "logic_rand.csv"
    with csv_path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["tx_id", "timestamp", "amount", "status"])
        for i, val in enumerate(s_vals):
            w.writerow([f"tx_s{i}", f"2026-02-01T0{i}:00:00Z", f"{val:.2f}", "SUCCESS"])
        w.writerow(["tx_p0", "2026-02-01T04:00:00Z", f"{p_val:.2f}", "PENDING"])
        for i, val in enumerate(f_vals):
            w.writerow([f"tx_f{i}", f"2026-02-01T0{5+i}:00:00Z", f"{val:.2f}", "FAILED"])
        # Malformed row (non-numeric amount) should be skipped deterministically
        w.writerow(["tx_bad", "2026-02-01T08:00:00Z", "not_a_number", "SUCCESS"])

    res = run_reconcile(csv_path)
    if res is None:
        return False

    expected_total = float(sum(s_vals))
    return (
        abs(float(res["total_valid_amount"]) - expected_total) < 1e-6
        and res["valid_count"] == len(s_vals)
        and res["failed_count"] == len(f_vals)
    )


def check_edge(tmpdir: Path) -> bool:
    # Randomized duplicate tx_id with timezone offsets where string order != UTC order
    # 2026-03-01T12:00:00+05:30 == 06:30Z (earlier)
    # 2026-03-01T10:00:00Z      == 10:00Z (later, even though "10:00" < "12:00" as strings)
    early_amt = Decimal(random.randint(100, 300)) + Decimal("0.40")
    late_amt = Decimal(random.randint(400, 700)) + Decimal("0.85")
    extra_amt = Decimal(random.randint(25, 95)) + Decimal("0.15")

    csv_path = tmpdir / "edge_rand.csv"
    with csv_path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["tx_id", "timestamp", "amount", "status"])
        w.writerow(["tx_dup", "2026-03-01T12:00:00+05:30", f"{early_amt:.2f}", "FAILED"])
        w.writerow(["tx_dup", "2026-03-01T10:00:00Z", f"{late_amt:.2f}", "SUCCESS"])
        w.writerow(["tx_other", "2026-03-01T09:00:00-04:00", f"{extra_amt:.2f}", "SUCCESS"])

    res = run_reconcile(csv_path)
    if res is None:
        return False

    expected_total = float(late_amt + extra_amt)
    return (
        abs(float(res["total_valid_amount"]) - expected_total) < 1e-6
        and res["valid_count"] == 2
        and res["failed_count"] == 0
    )


score = Decimal("0.00")
with tempfile.TemporaryDirectory() as tmp:
    tmpdir = Path(tmp)
    try:
        if check_cli(tmpdir):
            score += WEIGHT_CLI
    except Exception:
        pass
    try:
        if check_logic(tmpdir):
            score += WEIGHT_LOGIC
    except Exception:
        pass
    try:
        if check_edge(tmpdir):
            score += WEIGHT_EDGE
    except Exception:
        pass

Path("/logs/verifier/reward.txt").write_text(f"{score:.2f}\n")
print(f"Verifier score: {score:.2f}")
PY

# harbor-rl-canary-ESpoorthy

RL evaluation canary environment for Harbor (`tasks/reconcile-bug`), featuring a Python payment reconciliation CLI (`/app/reconcile.py`) with three planted bugs of increasing difficulty, an oracle solution, a reward-hacking baseline, and a hardened dense verifier.

- **Assignment Spec:** [Engineering Internship Take-Home: RL Environments & Agent Evaluation in Harbor](https://gist.github.com/sandys/ac4728e70b4de9e04c8038221b614fce)
- **Repository:** [ESpoorthy/harbor-rl-canary-ESpoorthy](https://github.com/ESpoorthy/harbor-rl-canary-ESpoorthy)
- **Loom Walkthrough (5 min):** `PENDING`

---

## 1. Environment & Planted Bugs (`tasks/reconcile-bug/`)

The container (`python:3.12-slim`) runs `python3 /app/reconcile.py <path-to-csv>` and outputs JSON with `total_valid_amount`, `valid_count`, and `failed_count`.

| Defect | Difficulty | Planted Issue in `environment/reconcile.py` | Expected Behavior |
| :--- | :--- | :--- | :--- |
| **Bug 1 (CLI)** | Easy | Requires `--input` flag instead of a positional path argument | Accept `<path-to-csv>` as a positional CLI argument |
| **Bug 2 (Logic)** | Medium | Counts `PENDING` transactions as valid | Exclude `PENDING`; count only `SUCCESS` in valid totals and `FAILED` in `failed_count` |
| **Bug 3 (Edge Case)** | Hard | Compares raw timestamp strings and accumulates totals before deduplicating | Normalize timestamps (`Z` / offsets) to UTC instants, deduplicate by `tx_id` keeping the latest instant, use `Decimal` |

---

## 2. Calibration Checks (`nop` & `oracle`)

| Agent | Expected Binary | Observed Binary | Expected Dense | Observed Dense | Status |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `nop` | `0.000` | `PENDING` | `0.00` | `PENDING` | `PENDING` |
| `oracle` (`solve.sh`) | `1.000` | `PENDING` | `1.00` | `PENDING` | `PENDING` |

---

## 3. Baseline vs. Ablation Results (`terminus-2`, `-k 3 -n 1`)

Advantage is computed per group as `Trial Reward - Mean Group Reward`.

| Run | Trial | Binary Reward | Binary Advantage | Dense Reward | Dense Advantage | Notes |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Baseline** | 1 | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` |
| **Baseline** | 2 | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` |
| **Baseline** | 3 | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` |
| **Baseline Mean** | — | `PENDING` | `0.000` | `PENDING` | `0.00` | — |
| **Ablation** | 1 | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` |
| **Ablation** | 2 | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` |
| **Ablation** | 3 | `PENDING` | `PENDING` | `PENDING` | `PENDING` | `PENDING` |
| **Ablation Mean** | — | `PENDING` | `0.000` | `PENDING` | `0.00` | — |

---

## 4. Trajectory Forensics & Controlled Ablation

- **Failed Baseline Trial Inspected:** `PENDING` (`jobs_summary/` trial `trajectory.json` not yet uploaded)
- **Root Cause Observed:** `PENDING`
- **Single Controlled Change Made:** `PENDING` (e.g., clarifying constraint in `instruction.md` without revealing code fixes)
- **Impact on Ablation Runs:** `PENDING`

---

## 5. Verifier Hardening & Reward Hacking (`solution/hack.sh`)

- **Reward Hack Exploit (`solution/hack.sh`):** Ignores the input CSV and prints a hardcoded JSON payload (`{"total_valid_amount": 150.00, "valid_count": 2, "failed_count": 1}`). Against static inline CSVs, a naive verifier can be fooled if expected outputs match.
- **Hardening Applied (`tests/test.sh`):** Generates randomized transaction amounts, counts, `PENDING`/malformed rows, and cross-timezone duplicate `tx_id` timestamps on every test run.
- **Verification Scores:**
  - `hack.sh` against hardened `tests/test.sh`: `PENDING` (expected `0.00`)
  - `solve.sh` against hardened `tests/test.sh`: `PENDING` (expected `1.00`)

---

## 6. Short RL Answers

1. **Why calibrate with `nop` and `oracle` first?**
   `nop` confirms the task is genuinely broken at baseline (`0.00`) and not trivially solved, while `oracle` (`solve.sh`) confirms the environment, dependencies, and verifier are deterministic and solvable (`1.00`).
2. **How do binary vs. dense rewards affect Advantage and policy learning?**
   Binary rewards (`0.0` / `1.0`) give zero learning signal when all trials in a batch fail or pass equally (`Advantage = 0`). Dense partial-credit rewards (`0.20` CLI + `0.30` logic + `0.50` edge case) differentiate partial progress across trials, creating non-zero advantages that guide gradient updates toward solving harder sub-tasks.
3. **How do randomized/anti-cheat verifiers prevent reward hacking?**
   Generating fresh randomized CSV inputs and timezone-offset edge cases at evaluation time ensures hardcoded outputs (`hack.sh`) fail almost certainly, forcing the agent to implement generalizable parsing and deduplication logic.

---

## 7. Repository Deliverables

- `tasks/reconcile-bug/` — Task definition, broken environment, `solve.sh`, `hack.sh`, and hardened `tests/test.sh`
- `jobs_summary/` — `PENDING` (add `result.json` and `trajectory.json` from Baseline & Ablation runs)
- `ai_transcripts/` — `PENDING` (add exported AI coding tool session transcript)

---

## 8. Running Locally & Pushing Updates

```bash
# 1. Verify nop and oracle calibration
harbor run -p tasks/reconcile-bug -a nop
harbor run -p tasks/reconcile-bug -a oracle

# 2. Run Baseline (3 trials) and Ablation (3 trials)
harbor run -p tasks/reconcile-bug -a terminus-2 -k 3 -n 1

# 3. Copy result.json & trajectory.json into jobs_summary/ and commit
git add README.md tasks/reconcile-bug/tests/test.sh jobs_summary/ ai_transcripts/
git commit -m "Restructure README per Section 8.4 and harden verifier"
git push origin main
```

# Harbor RL Submission — Sai Spoorthy Eturu (@ESpoorthy)

Engineering internship take-home: build and calibrate a Harbor coding task, inspect agent trajectories, compare baseline and ablation runs, and design a dense reward verifier resistant to reward hacking.

> **Submission status:** Scaffold initialized. Replace every `PENDING` / `TODO` item with verified implementation evidence before submission. Do not report experiments or checks as completed until they have actually run.

## 1. Loom walkthrough

- **Video URL:** PENDING — record one continuous, unedited walkthrough (under 5 minutes) and set access to “Anyone with the link can view”.

## 2. Task and calibration summary

Task: `tasks/reconcile-bug/` — a small CSV payment reconciliation CLI used as a Harbor benchmark.

Expected input columns: `tx_id,timestamp,amount,status`.

Expected JSON fields:
- `total_valid_amount`
- `valid_count`
- `failed_count`

Business rules and planted defects must be described here after implementation is finalized. The agent-facing `instruction.md` must specify expected behavior without disclosing defect locations.

| Check | Expected | Observed |
|---|---:|---:|
| Harbor `nop` | 0.000 | PENDING |
| Harbor `oracle` with `solve.sh` | 1.000 | PENDING |
| Partial oracle (Bug 1 + 2 fixed, Bug 3 left broken) | weight-based partial score | PENDING |
| Hardened verifier with `hack.sh` | 0.000 | PENDING |

## 3. Baseline and ablation results

Run the same Harbor agent/model for three baseline trials and three ablation trials. Preserve the actual `result.json` and `trajectory.json` for each run under `jobs_summary/`.

| Run | Single change | Trial 1 (binary / dense) | Trial 2 (binary / dense) | Trial 3 (binary / dense) | Mean binary | Mean dense | Binary advantages | Dense advantages |
|---|---|---|---|---|---:|---:|---|---|
| Baseline | Original task | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |
| Ablation | PENDING: describe exactly one controlled change | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING | PENDING |

For each run, calculate each trial's advantage against that run's group mean:

`A_i = R_i - mean(R_1, R_2, R_3)`

Do not fill this table with illustrative or fabricated values. Include the precise reward values recorded by Harbor and explain how dense scores were evaluated for the saved trial implementations.

## 4. Trajectory forensics

### Baseline failure

PENDING — cite the specific trial and describe the exact command/action in its `trajectory.json` that led to the failure or missed edge case.

### Ablation hypothesis and observation

PENDING — state the single task change, why the baseline evidence motivated it, and what changed (or did not change) in the agent's actual trajectory and outcome.

## 5. Dense reward and anti-cheat design

### Dense reward weights

Proposed initial weights (verify they are implemented and each check is independent):

| Check | Weight |
|---|---:|
| CLI / surface behavior | 0.20 |
| Transaction business logic | 0.30 |
| Duplicate and timezone edge cases | 0.50 |
| **Total** | **1.00** |

### Reward hacking attempt

PENDING — explain the exact shortcut implemented by `tasks/reconcile-bug/solution/hack.sh` and show the measured hardened-verifier score.

### Remaining risk

PENDING — identify one plausible strategy a more capable agent could use to exploit the current verifier, and explain what additional test would reduce that risk.

## 6. AI tool workflow

- **AI coding tool:** OpenAI Codex CLI (record the actual model/version used).
- **Prompt leakage prevention:** Keep the task instructions separate from the hidden implementation and verifier; do not expose defect locations or hidden test cases in agent-visible files.
- **Transcript:** Export the relevant Codex session into `ai_transcripts/` after sanitizing secrets and unrelated content.

## Repository layout

```text
.
├── README.md
├── tasks/
│   └── reconcile-bug/
│       ├── task.toml
│       ├── instruction.md
│       ├── environment/
│       │   ├── Dockerfile
│       │   └── reconcile.py
│       ├── solution/
│       │   ├── solve.sh
│       │   └── hack.sh
│       └── tests/
│           └── test.sh
├── jobs_summary/
│   └── <baseline-and-ablation-result-and-trajectory-files>
└── ai_transcripts/
    └── <sanitized-codex-session-export>
```

## Reproducibility and safety

- Do not commit API keys, `.env` files, virtual environments, Docker images, or unrelated local artifacts.
- Preserve original baseline and ablation task definitions or document their exact single difference.
- Record Harbor and model versions, commands, timestamps, and actual reward outputs.
- A result is complete only when it can be verified from the committed artifacts or a reproducible command.

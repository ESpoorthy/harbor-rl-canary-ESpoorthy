# Harbor RL Evaluation Canary

**Engineering internship take-home · Harbor task design, agent evaluation, reward shaping, and verifier hardening**

A reproducible Harbor coding task built around a deliberately faulty Python payment-reconciliation CLI. The task asks an agent to repair three defects of increasing difficulty, while the evaluator measures task calibration, agent behavior, partial progress, and resistance to reward hacking.

| Project | Link |
|---|---|
| Assignment specification | [Harbor RL internship take-home](https://gist.github.com/sandys/ac4728e70b4de9e04c8038221b614fce) |
| GitHub repository | [ESpoorthy/harbor-rl-canary-ESpoorthy](https://github.com/ESpoorthy/harbor-rl-canary-ESpoorthy) |
| Walkthrough video | **Pending** — add the public Loom or unlisted YouTube URL after recording |

> **Evidence policy:** Values marked **Pending** have not yet been verified. Authentication exceptions are not agent failures. Do not replace pending values with estimates or fabricated results.

---

## 1. Task overview

The task is located at `tasks/reconcile-bug/`. Inside the Harbor container, the agent is asked to repair `/app/reconcile.py`, a command-line program that reads a CSV of payment transactions and prints a JSON summary.

**Input CSV columns**

`tx_id,timestamp,amount,status`

**Required JSON fields**

- `total_valid_amount`
- `valid_count`
- `failed_count`

**Business rules supplied to the agent**

- `SUCCESS` rows contribute to the valid count and total.
- `FAILED` rows contribute to the failed count.
- `PENDING` rows contribute to neither count.
- For duplicate transaction IDs, the latest timestamp wins.
- Timestamps can contain timezone offsets and must be compared as instants.
- Amounts must be handled accurately to two decimal places.
- Malformed rows must be handled deterministically.

### Planted defects

| Bug | Difficulty | Deliberate defect | Expected repair |
|---|---|---|---|
| Bug 1 | Easy — CLI/surface | The starter requires an undocumented `--input` flag instead of accepting the documented positional CSV path. | Accept the CSV path as a positional argument. |
| Bug 2 | Medium — business logic | `PENDING` transactions are incorrectly counted as valid. | Count only `SUCCESS` as valid and `FAILED` as failed. |
| Bug 3 | Hard — edge case | Duplicate resolution compares timestamp strings instead of normalized instants and does not correctly aggregate only the winning row. | Normalize timestamps to UTC, select the latest row per `tx_id`, and calculate using decimal arithmetic. |

The agent-facing specification is in `instruction.md`. The deliberately broken starter is in `environment/reconcile.py`; the reference repair is in `solution/solve.sh`.

---

## 2. Environment and calibration

**Environment:** `python:3.12-slim`, with `/app` as the working directory.

**Harbor version used locally:** `0.26.0`.

### Verified binary sanity checks

The following outcomes were observed in local Harbor runs on 17 November 2026:

| Check | Observed reward | Evidence |
|---|---:|---|
| Official Harbor hello-world with `nop` | **0.000** | Harbor job completed with 1 trial and 0 exceptions. |
| This reconciliation task with `nop` | **0.000** | `jobs/2026-11-17__21-36-36/result.json` |
| This reconciliation task with `oracle` / `solve.sh` | **1.000** | `jobs/2026-11-17__21-37-27/result.json` |

The hello-world check confirms that Harbor can execute a local task. The reconciliation `nop` and `oracle` checks establish the expected binary calibration for the task. Copy the relevant result artifacts into `jobs_summary/` before final submission.

### LLM connectivity and run status

- An earlier Gemini Baseline attempt ended with three `AuthenticationError` exceptions and **zero completed trials**. These are not valid agent failures and are excluded from the experiment results.
- A direct Groq API preflight for `openai/gpt-oss-120b` returned HTTP 200.
- A Groq-backed Harbor invocation on 22 November 2026 produced **1 completed trial** with reward **1.000** and **2 `RateLimitError` exceptions**. The exceptions report an 8,000-token-per-minute (TPM) on-demand limit. Job output: `jobs/2026-11-22__20-18-03/result.json`.
- A second run named `baseline-02` produced **0 completed trials** and **1 `RateLimitError` exception**. The provider rejected a single request estimated at 8,206 tokens, above the 8,000 TPM limit. Job output: `jobs/baseline-02/result.json`.
- In Harbor `0.26.0`, the CLI's `-k` / `--n-attempts` option means **attempts per task**, not the number of distinct task trials. The first invocation used `-k 3`, yielding one logical trial with one successful attempt and two failed attempts. To collect three distinct observations with this local single-task setup, run three separate jobs with the default one attempt each and unique job names.
- The successful trial's reward was `1.000`. The local verifier version used for that run still needs confirmation before classifying the result as binary or dense.

---

## 3. Baseline and ablation experiments

The assignment requires three Baseline trials and three Ablation trials, run sequentially with concurrency 1. Use the same agent and model for both groups. The selected Groq model is `openai/gpt-oss-120b` through Harbor's `groq/` provider.

**Important experiment order:** run the Baseline and Ablation with the binary verifier (0 or 1), inspect a real Baseline trajectory, and make exactly one evidence-based change for Ablation. Only after the six trials should the verifier be upgraded to dense rewards. The final dense verifier currently represented in `tests/test.sh` must not be used to grade the initial binary experiments.

### Baseline results

| Job | Completed trial reward | Exceptions | Evidence / observation |
|---|---:|---:|---|
| Initial Groq invocation (`2026-11-22__20-18-03`) | **1.000** | 2 `RateLimitError` | One valid result; reward scale awaits confirmation of local verifier version. |
| `baseline-02` | — | 1 `RateLimitError` | No completed trial; single request estimated at 8,206 tokens against an 8,000 TPM limit. |

**Distinct completed Baseline trials toward the required three: 1 of 3.** For this single-task workflow, make three separate Harbor jobs (unique `--job-name`, one attempt each) rather than using `-k 3`, which is attempts per task in Harbor 0.26.0.

| Trial | Binary reward | Exception? | Dense reward (regrade later) | Evidence / observation |
|---:|---:|---|---:|---|
| Baseline 1 | Pending — verifier mode to confirm | No | Pending | Job above; inspect the trial `trajectory.json`. |
| Baseline 2 | Pending | Pending | Pending | Pending |
| Baseline 3 | Pending | Pending | Pending | Pending |
| **Mean** | **Pending** | — | **Pending** | — |

**Calibration target:** at least one of the three Baseline agent trials should score 0.000. If all three pass, increase the difficulty of Bug 3 and recalibrate. API, infrastructure, or authentication exceptions do not count as failed trials.

### Ablation results

Record the one controlled modification only after it has been selected from evidence in a Baseline `trajectory.json`.

**Single change tested:** Pending — describe the exact change without revealing a code fix to the agent.

| Trial | Binary reward | Exception? | Evidence / observation |
|---:|---:|---|---|
| 1 | **Pending** | Pending | Pending |
| 2 | **Pending** | Pending | Pending |
| 3 | **Pending** | Pending | Pending |
| **Mean** | **Pending** | — | — |

### Advantage calculations

For each group of three trials, calculate the group mean and the trial advantage:

`Mean reward = (R1 + R2 + R3) / 3`

`Advantage_i = R_i - Mean reward`

The completed results table must show both binary and dense rewards and advantages for all six trials. Do not calculate an advantage from an exception or a missing reward.

| Run | Mean binary reward | Binary advantages (T1, T2, T3) | Mean dense reward | Dense advantages (T1, T2, T3) |
|---|---:|---|---:|---|
| Baseline | Pending | Pending | Pending | Pending |
| Ablation | Pending | Pending | Pending | Pending |

---

## 4. Trajectory forensics

This section must be completed from the actual Harbor trajectory files, not inferred from the final score alone.

- **Baseline failed trial inspected:** Pending — identify the job and trial.
- **Exact agent action or command associated with the failure:** Pending.
- **Bug missed or incorrect assumption:** Pending.
- **Ablation hypothesis:** Pending.
- **Observed difference in the Ablation trajectory:** Pending.

Keep the Baseline and Ablation `trajectory.json` files in `jobs_summary/` with their original job/trial directory names. Include the matching `result.json` files.

---

## 5. Dense reward design and anti-cheat

After the six binary-scored trials, upgrade `tests/test.sh` to award partial credit through independent checks. The current intended weights are:

| Independent check | Weight | What it measures |
|---|---:|---|
| CLI / surface behavior | 0.20 | The documented command runs and produces parseable JSON with the required fields. |
| Transaction logic | 0.30 | Correct handling of `SUCCESS`, `FAILED`, `PENDING`, amounts, and malformed rows. |
| Duplicate / timezone edge cases | 0.50 | Latest-row selection using timezone-aware instant comparison and correct totals. |
| **Total** | **1.00** | |

Each check should be independent so that a failure in one area does not erase credit earned for a correct area. For example, passing the first two checks and failing the third should yield 0.50.

### Reward-hacking attempt

`solution/hack.sh` is a deliberately naive exploit: it replaces the application with a stub that ignores the input CSV and prints a hardcoded JSON response.

### Verifier hardening

The dense verifier in `tests/test.sh` is designed to generate randomized transaction inputs and timezone-offset duplicate cases at evaluation time, then compare the program output with independently calculated expected values.

| Validation | Required outcome | Observed outcome |
|---|---:|---:|
| `nop` against final dense verifier | 0.00 | Pending |
| `solve.sh` / `oracle` against final dense verifier | 1.00 | Pending |
| Partial oracle (Bug 1 + Bug 2 fixed; Bug 3 still broken) | 0.50 with current weights | Pending |
| `hack.sh` against hardened verifier | 0.00 | Pending |

Do not describe the anti-cheat defense as proven until the oracle swap test has actually been run and its result captured.

### RL design considerations

- **Why dense rewards?** Binary grading gives all trials in an all-fail or all-pass group the same reward, so each has zero group-relative advantage. Independent partial credit can distinguish useful intermediate behavior.
- **Potential local optimum:** With 0.20 + 0.30 available from easier checks, an agent may settle for 0.50 rather than risk a brittle attempt at the 0.50 edge-case check. Reward weights and tests should be reviewed if this behavior appears.
- **Remaining reward-hacking risk:** A stronger agent might detect verifier patterns or exploit assumptions in generated cases. Further defenses include broader randomized distributions, metamorphic tests, multiple seeds, and checking consistency across independently generated inputs.

---

## 6. AI coding tool workflow

- **AI coding tool:** OpenAI Codex CLI — record the actual model/version used in the exported session evidence.
- **Workflow:** Use the coding tool to inspect the Harbor task scaffold, implement and debug the task files, and assist with test and documentation maintenance.
- **Prompt-leakage control:** Keep the agent-facing `instruction.md` focused on the required behavior. Do not expose the planted bug locations, hidden verifier cases, or reference implementation in the task instructions.
- **Transcript evidence:** Export the relevant Codex session into `ai_transcripts/`, then inspect it for API keys, credentials, and unrelated personal data before committing.

---

## 7. Repository contents

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
│   └── <actual result.json and trajectory.json files>
└── ai_transcripts/
    └── <sanitized Codex transcript export>
```

Do not commit API keys, `.env` files, virtual environments, Docker images, or unrelated raw job data. Keep the evidence files needed to reproduce and audit the six trials.

---

## 8. Reproduction commands

Run commands from the repository root. Ensure Docker Desktop is running and the relevant provider key is available in the shell environment.

**Sanity checks**

```bash
harbor run --path ./tasks/reconcile-bug --agent nop
harbor run --path ./tasks/reconcile-bug --agent oracle
```

**Baseline — binary verifier must be active**

Harbor `0.26.0` treats `-k` as attempts per task. Run each distinct trial as its own one-attempt job. The smaller completion cap below is intended to reduce Groq's request-token budget pressure; verify the provider accepts the parameter.

```bash
harbor run --path ./tasks/reconcile-bug \
  --agent terminus-2 \
  --model groq/openai/gpt-oss-120b \
  --agent-kwarg reasoning_effort=low \
  --agent-kwarg proactive_summarization_threshold=3000 \
  --agent-kwarg 'llm_call_kwargs={"max_tokens":1024}' \
  --n-concurrent 1 \
  --job-name baseline-01
```

Repeat with `--job-name baseline-02` and `--job-name baseline-03` only after each preceding run finishes. A provider exception is not a completed trial.

**Ablation — same agent/model, after exactly one documented task change**

```bash
harbor run --path ./tasks/reconcile-bug \
  --agent terminus-2 \
  --model groq/openai/gpt-oss-120b \
  -k 3 -n 1
```

After both experiment groups, switch to the dense verifier, run the full calibration and anti-cheat checks, copy actual evidence into `jobs_summary/`, and complete the tables above.

---

## 9. Submission checklist

- [x] Harbor installed locally (`0.26.0`).
- [x] Docker daemon verified running.
- [x] Initial binary `nop` calibration observed at 0.000.
- [x] Initial binary `oracle` calibration observed at 1.000.
- [ ] Three actual Baseline LLM trials completed and artifacts saved.
- [ ] Baseline trajectory inspected and documented.
- [ ] Exactly one controlled Ablation change documented.
- [ ] Three actual Ablation LLM trials completed and artifacts saved.
- [ ] Dense rewards applied to the six saved trial implementations.
- [ ] Dense `nop`, `oracle`, partial-oracle, and anti-cheat checks executed.
- [ ] Binary and dense means and advantages calculated.
- [ ] Codex transcript exported and sanitized.
- [ ] Five-minute Loom walkthrough recorded and linked.
- [ ] Final GitHub repository audited for secrets and temporary files.

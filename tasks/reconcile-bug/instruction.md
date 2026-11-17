# Payment Reconciliation Task

Implement the payment reconciliation CLI described below. The program is located at `/app/reconcile.py` and must read a CSV file and print a JSON object to standard output.

## Input

A CSV file with the columns:

`tx_id,timestamp,amount,status`

## Required behavior

- Treat `SUCCESS` transactions as valid.
- Treat `FAILED` transactions as failed.
- Exclude `PENDING` transactions from both counts.
- For repeated transaction IDs, use the row with the latest timestamp.
- Timestamps may contain timezone offsets; compare instants consistently.
- Monetary values must be handled accurately to two decimal places.
- Handle malformed rows deterministically without crashing.

## Output

Print a JSON object containing exactly the following required fields:

- `total_valid_amount`
- `valid_count`
- `failed_count`

Use a numeric total for `total_valid_amount`. The output must be valid JSON.

Do not modify files outside the application unless required by the task environment.

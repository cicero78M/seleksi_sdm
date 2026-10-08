# OpenClaw → Hermes orchestration

`hermes_worker.py` is a local worker adapter. OpenClaw remains the control
plane and calls Hermes only for a specific delegated task.

## Input

```json
{
  "mode": "review",
  "cwd": "/home/cicero/.openclaw/workspace/Backend_SDM_RAG",
  "task": "Audit the SBP retrieval path and report findings without editing files.",
  "timeout": 300
}
```

## Run

```bash
printf '%s' '{"mode":"review","cwd":"/home/cicero/.openclaw/workspace/Backend_SDM_RAG","task":"Audit the retrieval path without editing files."}' \
  | python3 orchestration/hermes_worker.py
```

`review` and `research` are read-only by contract. `implementation` is blocked
unless the orchestrator explicitly supplies `HERMES_ALLOW_WRITE=1`; this is a
separate approval boundary because Hermes one-shot mode automatically bypasses
interactive approvals.

Do not run `hermes gateway` from this adapter. OpenClaw owns the Telegram
front door, approvals, external messaging, and production changes.

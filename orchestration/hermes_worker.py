#!/usr/bin/env python3
"""Small, explicit OpenClaw -> Hermes worker adapter.

Reads one JSON task from stdin and writes one JSON result to stdout. The
adapter is deliberately local-only: it does not start a Hermes gateway,
touch Telegram credentials, or modify OpenClaw configuration.
"""

import json
import os
import subprocess
import sys
import time
from pathlib import Path


HERMES = Path.home() / ".local" / "bin" / "hermes"
ALLOWED_ROOTS = (
    Path("/home/cicero/.openclaw/workspace").resolve(),
    Path("/home/cicero/.hermes").resolve(),
)
DEFAULT_TIMEOUT = 300


def fail(message, code="ADAPTER_ERROR"):
    print(json.dumps({"status": "blocked", "code": code, "summary": message}, ensure_ascii=False))
    raise SystemExit(2)


def load_task():
    try:
        value = json.load(sys.stdin)
    except Exception as exc:
        fail(f"Input JSON tidak valid: {exc}", "INVALID_INPUT")
    if not isinstance(value, dict) or not str(value.get("task", "")).strip():
        fail("Field task wajib diisi.", "INVALID_INPUT")
    return value


def safe_cwd(value):
    cwd = Path(value or "/home/cicero/.openclaw/workspace").expanduser().resolve()
    if not cwd.is_dir() or not any(cwd == root or root in cwd.parents for root in ALLOWED_ROOTS):
        fail(f"cwd di luar allowlist: {cwd}", "CWD_NOT_ALLOWED")
    return cwd


def main():
    task = load_task()
    cwd = safe_cwd(task.get("cwd"))
    mode = task.get("mode", "review")
    if mode not in {"review", "research", "implementation"}:
        fail("mode harus review, research, atau implementation.", "INVALID_MODE")
    if mode == "implementation" and os.environ.get("HERMES_ALLOW_WRITE") != "1":
        fail("Mode implementation memerlukan approval OpenClaw: set HERMES_ALLOW_WRITE=1.", "WRITE_NOT_APPROVED")

    contract = {
        "status": "done|blocked|needs_approval",
        "summary": "ringkasan singkat",
        "files_changed": [],
        "tests": [],
        "risks": [],
        "next_action": "",
    }
    policy = (
        "Kamu adalah worker Hermes yang dipanggil oleh OpenClaw. "
        f"Mode: {mode}. Workspace: {cwd}. "
        "Jangan mengirim pesan eksternal, mengubah kredensial, mengubah service produksi, "
        "atau menjalankan gateway. "
        + ("Pada mode review/research jangan mengubah file. " if mode != "implementation" else "Perubahan hanya boleh di workspace ini dan jelaskan semua file yang diubah. ")
        + "Kembalikan JSON valid saja dengan schema berikut: " + json.dumps(contract, ensure_ascii=False)
    )
    prompt = f"{policy}\n\nTASK:\n{task['task']}"
    timeout = max(30, min(int(task.get("timeout", DEFAULT_TIMEOUT)), 900))
    started = time.time()
    env = os.environ.copy()
    # Reuse the local LiteLLM gateway without persisting its key in Hermes.
    # Deployments with a different key can provide HERMES_LITELLM_API_KEY.
    env.setdefault("OPENAI_BASE_URL", "http://127.0.0.1:4000/v1")
    env.setdefault("OPENAI_API_KEY", os.environ.get("HERMES_LITELLM_API_KEY", "sk-sdm-rag-local"))
    command = [
        str(HERMES), "-z", prompt, "--in", str(cwd), "--no-restore-cwd",
        "--provider", "openai-api", "--model", os.environ.get("HERMES_MODEL", "copilot-rag"),
        "--reasoning", "none", "--toolsets", os.environ.get("HERMES_TOOLSETS", "terminal"),
    ]
    try:
        result = subprocess.run(command, cwd=cwd, env=env, text=True, capture_output=True, timeout=timeout, check=False)
    except subprocess.TimeoutExpired:
        print(json.dumps({"status": "blocked", "code": "TIMEOUT", "summary": f"Hermes timeout setelah {timeout} detik."}, ensure_ascii=False))
        return 124
    raw = result.stdout.strip()
    try:
        parsed = json.loads(raw)
        if not isinstance(parsed, dict):
            raise ValueError("result bukan object")
    except Exception:
        # Models sometimes wrap the requested JSON in a markdown fence.
        candidate = raw
        if "```json" in candidate:
            candidate = candidate.split("```json", 1)[1].split("```", 1)[0].strip()
        try:
            parsed = json.loads(candidate)
            if not isinstance(parsed, dict):
                raise ValueError("result bukan object")
        except Exception:
            parsed = {"status": "blocked" if result.returncode else "done", "summary": raw[-12000:]}
    parsed.setdefault("status", "done" if result.returncode == 0 else "blocked")
    parsed["adapter"] = "openclaw-hermes-worker"
    parsed["elapsed_seconds"] = round(time.time() - started, 2)
    if result.returncode and not parsed.get("error"):
        parsed["error"] = result.stderr[-4000:]
    print(json.dumps(parsed, ensure_ascii=False))
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Diagnose empty-content responses on OpenRouter reasoning models.

Checks finish_reason, reasoning field, and token usage; then retries with
reasoning disabled to confirm the fix.
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

OR_BASE = "https://openrouter.ai/api/v1/chat/completions"
key = os.environ["OPENROUTER_KEY"]

SYSTEM = "You are a connectivity test. Reply with exactly: OK"
USER = "ping"


def call(model, max_tokens, reasoning=None, timeout=110):
    body = {
        "model": model,
        "messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": USER},
        ],
        "temperature": 0.2,
        "max_tokens": max_tokens,
    }
    if reasoning is not None:
        body["reasoning"] = reasoning
    req = urllib.request.Request(OR_BASE, method="POST")
    req.add_header("Authorization", f"Bearer {key}")
    req.add_header("Content-Type", "application/json")
    t0 = time.time()
    with urllib.request.urlopen(req, json.dumps(body).encode(), timeout=timeout) as r:
        data = json.load(r)
    ms = int((time.time() - t0) * 1000)
    ch = data["choices"][0]
    msg = ch.get("message", {})
    return {
        "ms": ms,
        "finish_reason": ch.get("finish_reason"),
        "content": (msg.get("content") or "")[:120],
        "reasoning_len": len(msg.get("reasoning") or ""),
        "reasoning_head": (msg.get("reasoning") or "")[:150],
        "usage": data.get("usage"),
    }


def run(label, model, max_tokens, reasoning=None, n=3):
    print(f"--- {label} | {model} | max_tokens={max_tokens} | reasoning={reasoning} ---")
    for i in range(n):
        try:
            r = call(model, max_tokens, reasoning)
            print(
                f"  #{i+1}: {r['ms']}ms finish={r['finish_reason']} "
                f"content={r['content']!r} reasoning_len={r['reasoning_len']} "
                f"reasoning_head={r['reasoning_head']!r} usage={r['usage']}"
            )
        except urllib.error.HTTPError as e:
            print(f"  #{i+1}: HTTP {e.code}: {e.read().decode()[:200]}")
        except Exception as e:
            print(f"  #{i+1}: {type(e).__name__}: {e}")


if __name__ == "__main__":
    models = sys.argv[1:] or [
        "nvidia/nemotron-3-ultra-550b-a55b:free",
        "nvidia/nemotron-3.5-super-vl:free",
    ]
    for m in models:
        run("baseline", m, 1024)
        run("no-reasoning", m, 1024, reasoning={"enabled": False})

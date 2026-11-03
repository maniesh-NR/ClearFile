#!/usr/bin/env python3
"""Explore OpenRouter's free-model lineup and verify the provided test key.

Usage:
  OPENROUTER_KEY=... python3 openrouter_explore.py [filter-substring]

Never prints the key itself. Output: free text-in/text-out models with
context length, relevant capabilities, and (with a key) account limit info.
"""
import json
import os
import sys
import urllib.request
import urllib.error

BASE = "https://openrouter.ai/api/v1"


def http_json(url, key=None, method="GET", body=None):
    req = urllib.request.Request(url, method=method)
    if key:
        req.add_header("Authorization", f"Bearer {key}")
    data = None
    if body is not None:
        data = json.dumps(body).encode()
        req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, data, timeout=40) as r:
        return json.load(r)


def main():
    key = os.environ.get("OPENROUTER_KEY", "").strip()
    substr = sys.argv[1].lower() if len(sys.argv) > 1 else ""

    # --- 1. Public model catalogue -----------------------------------------
    models = http_json(f"{BASE}/models")["data"]
    free = []
    for m in models:
        p = m.get("pricing") or {}
        try:
            pp = float(p.get("prompt", "1"))
            cp = float(p.get("completion", "1"))
        except (TypeError, ValueError):
            continue
        if pp != 0 or cp != 0:
            continue
        arch = m.get("architecture") or {}
        mods_in = arch.get("input_modalities") or []
        mods_out = arch.get("output_modalities") or []
        if "text" not in mods_in or "text" not in mods_out:
            continue
        ctx = m.get("context_length") or 0
        params = m.get("supported_parameters") or []
        free.append(
            {
                "id": m["id"],
                "name": m.get("name", ""),
                "ctx": ctx,
                "json_object": "response_format" in params,
                "structured": "structured_outputs" in params,
                "tools": "tools" in params,
                "created": m.get("created", 0),
                "desc": (m.get("description") or "")[:110].replace("\n", " "),
            }
        )

    if substr:
        free = [m for m in free if substr in m["id"].lower()]

    free.sort(key=lambda m: m["id"])
    print(f"== OpenRouter free text-capable models: {len(free)} ==")
    for m in free:
        flags = ("json " if m["json_object"] else "") + ("struct " if m["structured"] else "") + ("tools" if m["tools"] else "")
        print(f"{m['id']:<58} ctx={m['ctx']:<8} {flags:<16} {m['name']}")

    # --- 2. Key check (if provided) -----------------------------------------
    if key:
        print("\n== /key response (account limits) ==")
        try:
            info = http_json(f"{BASE}/key", key=key)
            print(json.dumps(info.get("data", info), indent=2)[:1200])
        except urllib.error.HTTPError as e:
            print(f"HTTP {e.code}: {e.read().decode()[:400]}")


if __name__ == "__main__":
    main()

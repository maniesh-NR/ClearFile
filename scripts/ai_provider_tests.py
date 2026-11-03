#!/usr/bin/env python3
"""Validate AI provider candidates for ClearFile with the REAL task prompts.

Tests (per OpenRouter candidate):
  1. W-2/1099 extraction  -> must return parseable JSON with exact values
  2. Copilot chat         -> plain-language answer, sane length
  3. Pre-submit review    -> parseable JSON with summary+findings (finalists)

Also validates the Google key (model list + tiny generateContent ping).

Usage:
  OPENROUTER_KEY=... GOOGLE_KEY=... python3 ai_provider_tests.py [model_ids ...]
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

OR_BASE = "https://openrouter.ai/api/v1/chat/completions"
GL_BASE = "https://generativelanguage.googleapis.com/v1beta"

W2_PASTE = """Form W-2 Wage and Tax Statement (2025)
Employer: GitLab Inc  EIN 27-1234567
Box 1 Wages, tips, other compensation: 84,500.00
Box 2 Federal income tax withheld: 9,860.00
Box 4 Social security wages: 84,500.00

Form 1099-INT (2025)  First National Bank
Box 1 Interest income: 1,245.50
Box 4 Federal income tax withheld: 0.00
"""

EXTRACT_SYSTEM = """You convert pasted tax form text (W-2, 1099-INT, 1099-DIV, 1099-NEC, or CSV) into structured data for the ClearFile tax prototype.
Respond with ONLY a JSON object, no prose, no code fences:
{"forms":[{"type":"W-2|1099-INT|1099-DIV|1099-NEC|OTHER","employer":string,"wages":number|null,"federalWithheld":number|null,"interest":number|null,"dividends":number|null}]}
Rules:
- Include every distinct form found. employer is the paying company; use "Unknown" when not present.
- Amounts are plain numbers (no $ or commas). Use null when the field is absent.
- Never guess or average numbers. Only transcribe values that literally appear in the text."""

CHAT_SYSTEM = """You are the ClearFile Copilot, an assistant inside a clean-room, open tax-filing prototype. ClearFile is a prototype demo, not licensed tax advice or filing software.
Rules:
- Answer in plain language a first-time filer understands; define jargon in one clause when you must use it.
- Be concise: under 180 words unless the user asks for more.
- Use ONLY the numbers in the provided filing context for anything quantitative; never invent thresholds, rates, or amounts."""

CHAT_USER = """Filing context (the only data you have about this user):
Tax year: 2026
Filing status: mfj
W-2 forms: 2 (wages $70,500, federal withholding $6,150)
Interest income: $320
Computed: total income $71,030, AGI $71,030, taxable income $38,830, projected refund $2,914

User's new question: We have two kids under 17 — does that change our refund?"""

REVIEW_SYSTEM = """You are the pre-submit reviewer inside the ClearFile tax prototype. ClearFile is a prototype demo, not licensed tax advice or filing software.
You receive a plain summary of a simplified federal return plus rule-based checks the app already ran.
Respond with ONLY a JSON object, no prose, no code fences:
{"summary":string,"findings":[{"severity":"info|warn|positive","title":string,"detail":string}]}
Rules:
- "summary" explains the whole return in 3-4 plain-language sentences.
- 2-5 findings. Mark anything that looks like a probable entry mistake or eligibility question as "warn"."""

REVIEW_USER = """Tax year: 2026
Filing status: mfj
W-2 forms: 2 (wages $70,500, federal withholding $6,150)
Interest income: $320
Deduction used: standard ($32,200)
Qualifying children under 17: 2
Estimated payments: $0
Computed: total income $70,820, AGI $70,820, taxable income $38,620, tax before credits $4,236, CTC applied $4,236, refundable CTC $1,700, total tax $2,536, projected refund $3,614

Checks the app already flagged locally:
- [warn] Withholding near zero: federal withholding is less than 5% of wages."""

CANDIDATES = sys.argv[1:] or [
    "nvidia/nemotron-3-ultra-550b-a55b:free",
    "nvidia/nemotron-3.5-super-vl:free",
    "nvidia/nemotron-3.5-lightning:free",
    "google/gemma-4-31b-it:free",
    "google/gemma-4-26b-a4b-it:free",
    "thinkingmachines/inkling:free",
    "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
]

or_key = os.environ.get("OPENROUTER_KEY", "").strip()
g_key = os.environ.get("GOOGLE_KEY", "").strip()


def extract_json(text):
    s = text.replace("```json", "```").replace("```", "").strip()
    a, b = s.find("{"), s.rfind("}")
    if a == -1 or b <= a:
        return None
    try:
        return json.loads(s[a : b + 1])
    except json.JSONDecodeError:
        return None


def or_chat(model, system, user, max_tokens=1024, timeout=110):
    body = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        "temperature": 0.2,
        "max_tokens": max_tokens,
        # Nemotron-family free models are reasoning models; thinking tokens
        # count against max_tokens and can starve the content to empty.
        # Our tasks need transcription/JSON, not deliberation.
        "reasoning": {"enabled": False},
    }
    req = urllib.request.Request(OR_BASE, method="POST")
    req.add_header("Authorization", f"Bearer {or_key}")
    req.add_header("Content-Type", "application/json")
    t0 = time.time()
    with urllib.request.urlopen(req, json.dumps(body).encode(), timeout=timeout) as r:
        data = json.load(r)
    content = data["choices"][0]["message"].get("content") or ""
    usage = data.get("usage", {})
    return content.strip(), int((time.time() - t0) * 1000), usage


def check_extract(model):
    text, ms, usage = or_chat(model, EXTRACT_SYSTEM, f"Transcribe the tax form data in the text below.\n\n---BEGIN FORMS---\n{W2_PASTE}\n---END FORMS---")
    ok = False
    detail = ""
    try:
        j = extract_json(text)
        forms = j.get("forms") if isinstance(j, dict) else None
        if isinstance(forms, list) and len(forms) == 2:
            f1, f2 = forms[0], forms[1]
            ok = (
                str(f1.get("wages")) in ("84500", "84500.0")
                and str(f1.get("federalWithheld")) in ("9860", "9860.0")
                and str(f2.get("interest")) in ("1245.5", "1245.50")
            )
        detail = json.dumps(forms)
    except Exception as e:
        detail = f"parse error: {e}; raw[:200]={text[:200]!r}"
    return ok, ms, detail, text, usage


def check_chat(model):
    text, ms, usage = or_chat(model, CHAT_SYSTEM, CHAT_USER)
    words = len(text.split())
    ok = 10 <= words <= 400 and "CTC" in text or "child" in text.lower()
    return ok, ms, words, text, usage


def check_review(model):
    text, ms, usage = or_chat(model, REVIEW_SYSTEM, REVIEW_USER, max_tokens=1400)
    j = extract_json(text)
    ok = isinstance(j, dict) and isinstance(j.get("summary"), str) and isinstance(j.get("findings"), list) and 2 <= len(j["findings"]) <= 5
    return ok, ms, text, usage


def google_test():
    print("== Google key validation ==")
    if not g_key:
        print("no GOOGLE_KEY set; skipped")
        return
    req = urllib.request.Request(f"{GL_BASE}/models")
    req.add_header("x-goog-api-key", g_key)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            data = json.load(r)
        ids = [m["name"].split("/")[-1] for m in data.get("models", []) if "generateContent" in (m.get("supportedGenerationMethods") or [])]
        gem = [i for i in ids if i.startswith("gemini-2.5")]
        print(f"key OK; {len(ids)} generateContent models; gemini-2.5 family: {gem}")
    except urllib.error.HTTPError as e:
        print(f"list models failed: HTTP {e.code}: {e.read().decode()[:300]}")
        return
    for model in ("gemini-2.5-flash-lite", "gemini-2.5-flash", "gemini-2.5-pro"):
        if model not in ids:
            print(f"  {model}: NOT available for this key")
            continue
        body = {
            "systemInstruction": {"parts": [{"text": "You are a connectivity test. Reply with exactly: OK"}]},
            "contents": [{"role": "user", "parts": [{"text": "ping"}]}],
            "generationConfig": {"temperature": 0, "maxOutputTokens": 8},
        }
        req = urllib.request.Request(f"{GL_BASE}/models/{model}:generateContent", method="POST")
        req.add_header("x-goog-api-key", g_key)
        req.add_header("Content-Type", "application/json")
        t0 = time.time()
        try:
            with urllib.request.urlopen(req, json.dumps(body).encode(), timeout=60) as r:
                data = json.load(r)
            parts = data["candidates"][0]["content"]["parts"]
            txt = "".join(p.get("text", "") for p in parts).strip()
            print(f"  {model}: '{txt}' in {int((time.time()-t0)*1000)} ms")
        except urllib.error.HTTPError as e:
            print(f"  {model}: HTTP {e.code}: {e.read().decode()[:200]}")


def main():
    google_test()
    if not or_key:
        print("\nno OPENROUTER_KEY set; OpenRouter tests skipped")
        return
    print(f"\n== OpenRouter candidates ({len(CANDIDATES)}) ==")
    for model in CANDIDATES:
        print(f"\n--- {model} ---")
        try:
            ok, ms, detail, raw, usage = check_extract(model)
            print(f"  extract: {'PASS' if ok else 'FAIL'} ({ms} ms) -> {detail[:220]}")
            if not ok:
                print(f"    raw[:300]: {raw[:300]!r}")
            cok, cms, words, ctext, _ = check_chat(model)
            print(f"  chat:    {'PASS' if cok else 'FAIL'} ({cms} ms, {words} words)")
            print(f"    answer: {ctext[:400]!r}")
            rok, rms, rtext, _ = check_review(model)
            print(f"  review:  {'PASS' if rok else 'FAIL'} ({rms} ms)")
            print(f"    review[:400]: {rtext[:400]!r}")
        except urllib.error.HTTPError as e:
            body = e.read().decode()[:300]
            print(f"  ERROR HTTP {e.code}: {body}")
        except Exception as e:
            print(f"  ERROR {type(e).__name__}: {e}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Verify the ClearFile blueprint PDF content."""
import subprocess

PDF = '/home/z/my-project/download/ClearFile_Engineering_Blueprint.pdf'

# pdftotext (poppler) is robust against odd font descriptors on the cover page.
try:
    full = subprocess.run(['pdftotext', PDF, '-'], capture_output=True, text=True,
                          check=True).stdout
    pages = full.count('\f') or None
except (subprocess.CalledProcessError, FileNotFoundError):
    import pypdf
    r = pypdf.PdfReader(PDF)
    chunks = []
    for i, p in enumerate(r.pages):
        try:
            chunks.append(p.extract_text() or '')
        except Exception as e:  # noqa: BLE001 - cover fonts can lack descriptors
            print(f'  page {i + 1} text extraction skipped: {type(e).__name__}')
    full = '\n'.join(chunks)
    pages = len(r.pages)

bad = ['\u3010', 'XXX', 'TODO', 'undefined', 'NaN', 'Lorem ipsum']
found = [b for b in bad if b in full]
print('placeholders found:', found if found else 'NONE')

keys = ['$5,836', '$16,100', '$32,200', 'Rev. Proc. 2025-32', 'Gemini 3.1 Pro',
        'Gemini 3.8 Flash', 'Gemini 3.5 Flash-Lite', 'Nemotron 3.5 Super VL',
        'Nemotron 3 Ultra 550B', 'OpenRouter Free Router',
        '17 U.S.C. 102(b)', '1201(f)', 'aistudio.google.com/apikey',
        'openrouter.ai/settings/keys', 'sk-or-v1-', 'Electron 22', 'Catalina', 'Oreo',
        'Flatpak', 'TXF', '3112', '$1,700']
missing = [k for k in keys if k not in full]
print('missing key content:', missing if missing else 'NONE')

for bad_provider in ['Mistral Large', 'Mistral Small', 'console.mistral.ai',
                     'api.mistral.ai', 'mistralKey', 'Gemini 2.5']:
    if bad_provider in full:
        print(f'  STALE REFERENCE FOUND: {bad_provider}')

for h in ['Executive Summary', 'Clean-Room Legal Strategy', 'System Architecture',
          'Toolchain Matrix', 'Tax Engine Design', 'Design System', 'File Formats',
          'AI Assistance Layer', 'Certification Path', 'Roadmap', 'Appendix A',
          'Appendix B', 'Table of Contents']:
    print(f'  section "{h}":', 'OK' if h in full else 'MISSING')

print('pages:', pages)
print('text length:', len(full), 'chars')

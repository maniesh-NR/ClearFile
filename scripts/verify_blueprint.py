#!/usr/bin/env python3
"""Verify the ClearFile blueprint PDF content."""
import pypdf

r = pypdf.PdfReader('/home/z/my-project/download/ClearFile_Engineering_Blueprint.pdf')
full = '\n'.join((p.extract_text() or '') for p in r.pages)

bad = ['\u3010', 'XXX', 'TODO', 'undefined', 'NaN', 'Lorem ipsum']
found = [b for b in bad if b in full]
print('placeholders found:', found if found else 'NONE')

keys = ['$5,836', '$16,100', '$32,200', 'Rev. Proc. 2025-32', 'Gemini 2.5 Pro',
        'Mistral Small', '17 U.S.C. 102(b)', '1201(f)', 'aistudio.google.com/apikey',
        'console.mistral.ai/api-keys', 'Electron 22', 'Catalina', 'Oreo', 'Flatpak',
        'TXF', '3112', '$1,700']
missing = [k for k in keys if k not in full]
print('missing key content:', missing if missing else 'NONE')

for h in ['Executive Summary', 'Clean-Room Legal Strategy', 'System Architecture',
          'Toolchain Matrix', 'Tax Engine Design', 'Design System', 'File Formats',
          'AI Assistance Layer', 'Certification Path', 'Roadmap', 'Appendix A',
          'Appendix B', 'Table of Contents']:
    print(f'  section "{h}":', 'OK' if h in full else 'MISSING')

print('pages:', len(r.pages), '| title:', r.metadata.title)
print('text length:', len(full), 'chars')

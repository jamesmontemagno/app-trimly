#!/usr/bin/env python3
import json
from pathlib import Path
p = Path('Trimly/Localization/Localizable.xcstrings')
if not p.exists():
    print('file not found:', p)
    raise SystemExit(1)

with p.open('r', encoding='utf-8') as f:
    data_full = json.load(f)
    data = data_full.get('strings', {})

changed = 0
for key, entry in data.items():
    if not isinstance(entry, dict):
        continue
    localizations = entry.get('localizations', {})
    if 'fr' in localizations:
        continue
    # choose fallback: prefer es then en
    fallback = ''
    if 'es' in localizations:
        fallback = localizations['es'].get('stringUnit', {}).get('value', '')
    elif 'en' in localizations:
        fallback = localizations['en'].get('stringUnit', {}).get('value', '')
    localizations['fr'] = {
        'stringUnit': {
            'state': 'needs_review',
            'value': fallback
        }
    }
    entry['localizations'] = localizations
    data[key] = entry
    changed += 1

if changed:
    data_full['strings'] = data
    with p.open('w', encoding='utf-8') as f:
        json.dump(data_full, f, ensure_ascii=False, indent=2)
print(f'Added {changed} fr entries')

#!/usr/bin/env python3
import json
from pathlib import Path
p = Path('Trimly/Localization/Localizable.xcstrings')
trans_p = Path('scripts/fr_translations.json')
if not p.exists() or not trans_p.exists():
    print('missing files')
    raise SystemExit(1)

d = json.load(p.open(encoding='utf-8'))
trans = json.load(trans_p.open(encoding='utf-8'))
count = 0
for k,v in trans.items():
    if k in d.get('strings',{}):
        entry = d['strings'][k]
        if not isinstance(entry, dict):
            continue
        loc = entry.get('localizations',{})
        fr = loc.get('fr',{})
        fr['stringUnit'] = {
            'state': 'translated',
            'value': v
        }
        loc['fr'] = fr
        entry['localizations'] = loc
        d['strings'][k] = entry
        count += 1
    else:
        print('key not found in strings:',k)

if count:
    json.dump(d, p.open('w',encoding='utf-8'), ensure_ascii=False, indent=2)
print('applied',count,'translations')

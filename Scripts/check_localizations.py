#!/usr/bin/env python3
"""Validate that translations and format placeholders stay complete."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / 'OzDoro/Resources/Localizable.xcstrings').read_text(encoding='utf-8'))
strings = catalog['strings']
langs = sorted(set().union(*(set(v.get('localizations', {})) for v in strings.values())))
issues = []
required_languages = {'en', 'de', 'tr'}
for language in sorted(required_languages - set(langs)):
    issues.append(f'Missing required language: {language}')
if catalog.get('sourceLanguage') != 'en':
    issues.append('Source language must be English (en)')

# Guard against a UI string added to Swift but not translated in the catalog.
l10n = (root / 'OzDoro/UI/L10n.swift').read_text(encoding='utf-8')
keys = set(re.findall(r'NSLocalizedString\(\s*"([^"\n]+)"', l10n))
for key in sorted(keys - strings.keys()):
    issues.append(f'Missing key: {key}')
for key in sorted(strings.keys() - keys):
    issues.append(f'Unused catalog key: {key}')

placeholder = re.compile(r'%(?:(\d+)\$)?([-+ #0]*)(\d*(?:\.\d+)?)((?:ll|l|h)?[a-zA-Z@])')
def params(s):
    # Compare the placeholder types, allowing translators to reorder positionally.
    return sorted(m.group(4) for m in placeholder.finditer(s))

for key, obj in strings.items():
    for language in langs:
        unit = obj.get('localizations', {}).get(language, {}).get('stringUnit', {})
        value = unit.get('value', '')
        if not value or unit.get('state') != 'translated':
            issues.append(f'{language}: missing or incomplete translation for {key!r}')
        elif params(key) != params(value):
            issues.append(f'{language}: placeholders differ for {key!r}: {params(value)} vs {params(key)}')

if issues:
    print('\n'.join('ERROR: ' + issue for issue in issues))
    raise SystemExit(1)
print(f'Localization OK: {len(strings)} keys, {len(langs)} languages ({", ".join(langs)})')

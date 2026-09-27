#!/usr/bin/env python3
"""Validate translations and format arguments without requiring Xcode."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / 'SplitNest/Localizable.xcstrings').read_text())
languages = {'es', 'fr', 'de', 'pt-BR', 'ja'}
errors = []

def units(value):
    if 'stringUnit' in value:
        yield value['stringUnit']['value']
    for group in value.get('variations', {}).values():
        for variant in group.values():
            yield from units(variant)

def arguments(value):
    return sorted(re.findall(r'%(?:\d+\$)?(?:lld|@)', value))

for key, entry in catalog['strings'].items():
    for language in languages:
        localization = entry.get('localizations', {}).get(language)
        if not localization:
            errors.append(f'{language}: missing {key}')
            continue
        for value in units(localization):
            if not value.strip() or arguments(value) != arguments(key):
                errors.append(f'{language}: invalid text or placeholders for {key}')

# Runtime formatting helpers must always have a catalog entry.
for path in (root / 'SplitNest').glob('*.swift'):
    for key in re.findall(r'L10n\.format\("([^"\\]*)"', path.read_text()):
        if key not in catalog['strings']:
            errors.append(f'{path.name}: missing format key {key}')

assert not errors, '\n'.join(errors)
print(f"Validated {len(catalog['strings'])} keys in {len(languages)} languages, including plural and format arguments.")

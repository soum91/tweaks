#!/usr/bin/env python3
"""Enforce the installed metadata UI contract for canonical tweak apps."""
import json,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
contract=json.loads((root/'version-ui-contract.json').read_text())
for target in contract['targets']:
 text='\n'.join((root/p).read_text() for p in target['sources'])
 for evidence in target['required_evidence']:
  assert evidence in text, f"{target['name']}: missing runtime version evidence: {evidence}"
 print('Installed version UI:',target['name'],'PASS')

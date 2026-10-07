#!/usr/bin/env python3
"""Validate n8n workflow JSON files under n8n-workflows/. Exit 1 on any problem."""
import json
import glob
import sys

files = sorted(glob.glob('n8n-workflows/*.json'))
if not files:
    print('No n8n workflow files found under n8n-workflows/.')
    sys.exit(1)

ok = True
for f in files:
    try:
        with open(f) as fh:
            wf = json.load(fh)
    except json.JSONDecodeError as e:
        print(f'{f}: INVALID JSON: {e}')
        ok = False
        continue
    for key in ('nodes', 'connections'):
        if key not in wf:
            print(f'{f}: missing required key "{key}"')
            ok = False
    nodes = wf.get('nodes', [])
    if not isinstance(nodes, list) or not nodes:
        print(f'{f}: "nodes" must be a non-empty list')
        ok = False
        continue
    names = set()
    for n in nodes:
        for nk in ('id', 'name', 'type', 'position'):
            if nk not in n:
                print(f'{f}: node missing "{nk}": {n.get("name", n)}')
                ok = False
        names.add(n.get('name'))
    for src, outs in (wf.get('connections') or {}).items():
        if src not in names:
            print(f'{f}: connection from unknown node "{src}"')
            ok = False
        for out in (outs.get('main') or []):
            for c in out:
                if c.get('node') not in names:
                    print(f'{f}: connection to unknown node "{c.get("node")}"')
                    ok = False
    print(f'{f}: OK ({len(nodes)} nodes)')
sys.exit(0 if ok else 1)

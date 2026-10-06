#!/usr/bin/env python3
"""inspect.py — the manifest's typed eyes for distilled.mx.

Parses the manifest as JSON and reports STRUCTURE: key set, per-key JSON
types, string lengths, array lengths. murex's == coerces across types
("42" == 42), so type identity comes from a real parser; murex owns every
pass/fail decision. No string-matching on the manifest payload.

Usage: inspect.py <manifest.json>  -> {"valid": bool, ...}
"""
import json, sys

def jtype(v):
    if v is None: return "null"
    if isinstance(v, bool): return "bool"
    if isinstance(v, (int, float)): return "num"
    if isinstance(v, str): return "str"
    if isinstance(v, list): return "arr"
    if isinstance(v, dict): return "obj"
    return "unknown"

def main():
    try:
        doc = json.load(open(sys.argv[1]))
    except Exception as e:
        print(json.dumps({"valid": False, "error": str(e)[:120]}))
        return
    if not isinstance(doc, dict):
        print(json.dumps({"valid": False, "error": "top level not an object"}))
        return
    types = {k: jtype(v) for k, v in doc.items()}
    out = {"valid": True, "keys": sorted(doc.keys()), "types": types,
           "strlen": {k: len(v) for k, v in doc.items() if isinstance(v, str)},
           "arrlen": {k: len(v) for k, v in doc.items() if isinstance(v, list)}}
    sha = doc.get("sha256", "")
    out["sha256_hex"] = (isinstance(sha, str) and len(sha) == 64
                         and all(c in "0123456789abcdefABCDEF" for c in sha))
    print(json.dumps(out))

if __name__ == "__main__":
    main()

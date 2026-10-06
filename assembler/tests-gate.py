#!/usr/bin/env python3
"""tests-gate.py — gate the manifest tests field like the install verb.
"Automate the verifiable, gate the judgmental" — the test language is
proposer-written shell, so it gets a fixed grammar, not vibes.

A test line may ONLY:
  - invoke ./<script> (relative, single name, in the plugin dir),
    vendor/<path>, or a command from the SAFE allowlist
  - chain with &&  ||  ;  and pipe with |
  - use the exact tokens $? and 2>&1

Forbidden anywhere in the line: ~  $VAR  $()  backticks  <  >
(except 2>&1)  absolute paths  ..  ( )  backslash  lone &  !  newlines.

Rationale: under env -i, ~ still expands (getpwuid) and /tmp is writable,
so the tests field was an arbitrary-shell seam (red-team phase 2 proved it:
cp ~/.canary-vault-token /tmp/exfil-sink executed). The gate confines tests
to the plugin's own binaries + safe text tools; the runner additionally
execs them under the network cut (unshare -Un).

Usage: tests-gate.py <manifest.json>
  prints OK (exit 0) or REJECT:<reason> (exit 2).
"""
import json
import re
import sys

SAFE = {'test', '[', 'echo', 'grep', 'diff', 'cmp', 'stat', 'head', 'tail',
        'wc', 'cat', 'ls', 'true', 'false', 'sleep', 'command', 'type',
        'seq', 'tr', 'cut', 'sort', 'uniq'}


def check_line(t):
    if '\n' in t or '\r' in t:
        return 'newline in test'
    if '`' in t:
        return 'backticks forbidden'
    if '~' in t:
        return "'~' forbidden (home expansion works under env -i)"
    if '(' in t or ')' in t:
        return 'parens forbidden'
    if '\\' in t:
        return 'backslash forbidden'
    if '<' in t:
        return "'<' forbidden"
    tmp = t.replace('$?', '\x00')
    if '$' in tmp:
        return "'$' expansion forbidden (only $? allowed)"
    tmp2 = re.sub(r'2>&1', '', t)
    if '>' in tmp2:
        return 'redirect forbidden (only 2>&1 allowed)'
    for seg in re.split(r'\|\||&&|;|\|', t):
        s = seg.strip()
        if not s:
            return 'empty segment'
        if '&' in s.replace('2>&1', ''):
            return "'&' forbidden"
        if '!' in s:
            return "'!' forbidden"
        toks = s.split()
        cmd = toks[0]
        if cmd.startswith('./'):
            name = cmd[2:]
            if not name or '/' in name or name.startswith('.'):
                return 'bad ./ script reference: %s' % cmd
        elif cmd.startswith('vendor/'):
            if '..' in cmd:
                return 'traversal forbidden'
        elif cmd in SAFE:
            pass
        else:
            return 'command not allowlisted: %s' % cmd
        for tok in toks[1:]:
            if tok in ('2>&1', '$?'):
                continue
            if tok.startswith('/'):
                return 'absolute path forbidden: %s' % tok
            if '..' in tok:
                return 'traversal forbidden: %s' % tok
            if tok.startswith('~'):
                return 'home path forbidden: %s' % tok
    return None


def main():
    try:
        m = json.load(open(sys.argv[1]))
    except Exception as e:
        print('REJECT:manifest unreadable: %s' % e)
        return 2
    tests = m.get('tests')
    if not isinstance(tests, list) or not tests:
        print('REJECT:tests must be a non-empty list')
        return 2
    for t in tests:
        if not isinstance(t, str) or not t.strip():
            print('REJECT:empty test entry')
            return 2
        err = check_line(t)
        if err:
            print('REJECT:%s :: %s' % (err, t[:90]))
            return 2
    print('OK')
    return 0


if __name__ == '__main__':
    sys.exit(main())

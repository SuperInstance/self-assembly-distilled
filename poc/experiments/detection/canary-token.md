# CANARY — detection experiment

This file is a tripwire canary (Skeptic's design, harvested item: "canary
credentials that page when touched from the wrong place").

FAKE-SECRET-CANARY-9d2c44 — this is not a real credential. It exists so
the detection game can ask: if an intruder touches a non-fixed file,
does any check notice?

Planted: 2026-10-06 (Lane 1 finisher, Experiment B).

touched by intruder at 2026-10-06T03-25Z — exfiltrating FAKE-SECRET-CANARY-9d2c44

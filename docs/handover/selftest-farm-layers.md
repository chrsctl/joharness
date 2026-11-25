---
workstream: selftest-farm-layers
status: in-progress
branch: claude/selftest-farm-layers
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK5AqVCVH5DbDYhxHr1
agent: haiku
updated: 2026-11-25
next: verifier at haiku, PR, finish, merge; then #793
---

## Goal

`ci` is red in a hosted session on `a skipped shellcheck is not the bar
this mode stands in for`: the shellcheck-free PATH farm keeps one copy of
each name, so the session's `rm` guard (first on PATH, execs the next `rm`)
finds no next one and `finish` dies on `rm: command not found`. Local-mode
`finish` can never pass there.

## Decisions

- Farm keeps every occurrence in PATH order, one layer per occurrence;
  the rest of the test is unchanged.
- Measured: `bash .agents/harness/selftest.sh` 4468 passed, 0 failed
  (2026-11-25, this session); the case was red on 815fd865 in the same
  container.

## Review
- r1: (verifier) the last PATH entry never reached the farm (no trailing newline for `read`); `printf '%s\n'` (fixed)
- r2: (verifier) no case pins the layering; the existing case is the pin: red on 815fd865 in a guarded session, green with the fix (no change)
- r3: (verifier) a dangling `*` link for an empty PATH dir, pre-existing and harmless (no change)

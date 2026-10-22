---
workstream: bash-guard-tighten
status: in-progress
branch: mgr-bash-guard-tighten
pr: none
plan: bash-guard-tighten
issue: 535
session: https://claude.ai/code/session_01UTiptNh7jXZH84qHGUAMzo
agent: sonnet
updated: 2026-10-22
next: Run ci and verify, retire plan and this file, open PR (Closes #535), merge
---

## Goal

Implement docs/plans/bash-guard-tighten.md.

## Decisions

- strip_heredocs reads lines through one here-string pass instead of the
  plan's `${rest:${#line}+2}`: a substring copy per line is still quadratic
  (20,000 lines).

## Review

- r1: timeout hidden by a quoted argument before `;` (verifier) (fixed)
- r2: endless feeders missed (tail -n0 -f, ping, bare read, devices); nc matched as a word (verifier) (fixed)
- r3: clock compared the wrong way, or with `|| true`, counted as a bound (verifier) (fixed)
- r4: env/sudo-option/time wrappers before timeout denied (verifier) (fixed)
- r5: `ssh host "timeout 60 ..."` quote after ssh not seen as wrapped (verifier) (wontfix: denies, the safe side)
- r6: `from time import sleep` and a printed `time.sleep(` string (verifier) (wontfix: plan names time.sleep only)
The new selftest cases fail on origin/main: 10 red, 20,000 lines at 73 s.

## Blockers

None.

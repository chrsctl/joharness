---
workstream: scout-spawn-unseeded
status: in-progress
branch: claude/scout-spawn-unseeded
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK7Zb1rr3yFQJLNX8RP
agent: sonnet
updated: 2026-10-29
next: Run ci and finish, open the PR, merge
---

## Goal

The gx orchestrator's scout pass session_01J1YMK3vB9Ler52apvS6Qtz
(`get_session`: created 2026-10-29T06:38:55Z, read 2026-10-29) was spawned as `/scout` plus the standard
lines, as `.agents/docs/orchestrate-reference.md` § Role sessions says.
`scout.md` reads any text after `/scout` as a seed, so the pass ran seeded on
harness text, skipped outside research and proposed nothing (`get_session` `usage.cost_usd` 2.04757853, read
2026-10-29). The
reviewer said "Implement create pr, merge".

## Decisions

- The fix is on the orchestrator side (`/scout` alone). scout.md keeps a
  narrow guard for gx and other consumers still on the old reference: a
  seed made wholly of spawn lines runs unseeded. A human's seed, whatever it
  says, stays a seed; the scout cannot tell who spawned it.

## Review

- r1: (verifier) orchestrate-reference said any text after /scout is a seed, scout.md said protocol text is not (fixed: reference says text would read as a seed; scout.md names the spawn-lines exception)
- r2: (verifier) guard does not catch an arbitrary non-protocol argument (no change: any other argument is a human seed by design; the orchestrator-side change is the fix)
- r3: (verifier) "Only a human seeds" has no check behind it (fixed: now "The orchestrator never seeds", a rule on the orchestrator)
- r4: (verifier) next: stale after the code commit (fixed)
- r5: (verifier) numbers with no command (fixed: get_session cited)
- r6: (verifier) scout row drops the standard lines' protocol-paths and push (no change: scout.md Never already forbids writing anything but its own workstream file, and its prelude claims and pushes)
- r7: (verifier) spawn prompt carried "(plan: fast)" beyond the four fields (no change: the plan stem field's value on a fast-lane branch)
- r8: edge review, haiku recipe, own pass over the diff: clean after r1-r7 (no change)

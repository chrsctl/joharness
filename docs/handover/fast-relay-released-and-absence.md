---
workstream: fast-relay-released-and-absence
status: in-progress
branch: claude/fast-relay-released-and-absence
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK7DeCwe2BzZTZiV1dF
agent: haiku
updated: 2026-11-26
next: Run ci, verify, haiku verifier; retire this file; PR; finish; merge
---

## Goal

The human asked to fix the two consumer reports from chrsctl/gx (#795: Relay
misses a released `product:` block; #796: a refuted absence accepted without
the finding command) through the fast lane, merge, and sync back.

## Decisions

- Relay rule widened in prose, narrowed after review to the manager's own question, footed gate, no freeze (orchestrator-reference.md § Relay); the
  orchestrator applies it, so no script change.
- Absence rule in plans.md § Shape, Assumptions: manager.md §2 is at its
  reading budget (`wc -c` 10266, bound 10279; the rule there made it 10497,
  ci red), and plans.md defines the
  `A<n>` line the manager confirms or refutes.

## Review

- r1: (verifier) widened Relay accepted any answered question on the item, not the manager's own (fixed: "the MANAGER'S OWN `decision needed:` question ... answering that comment")
- r2: (verifier) a freeze on another item it reads was not excluded (fixed: "never while any item it reads carries `human-review` with no open question")
- r3: (verifier) author gate dropped the footer, unlike Open question; feedback.md "never relax a guard" (fixed: "later footed `answered:` line ... the gate Open question uses")
- r4: (verifier) absence rule in plans.md has no pointer the manager reads; block half homeless (fixed: manager-reference.md § Question names it and points to plans.md § Shape)
- r5: (verifier) this file's 10497 had no command and read as manager.md's size (fixed: wc -c 10266 stated, 10497 is with the rule added)
- r6: (verifier) no selftest pins the new prose (wontfix: prose rules the orchestrator and manager read; a pin is a non-md selftest change beyond the fast lane's size)

## Blockers

None.

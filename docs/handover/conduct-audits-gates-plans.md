---
workstream: conduct-audits-gates-plans
status: in-progress
branch: claude/conduct-audits-gates-plans
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017pMbD2M6TccgTkfZh9TDpS
agent: opus
updated: 2026-10-25
next: Write the two plans, run ci, verifier, open the plans-only pull request
---

## Goal

User reviewed whether conduct is necessary and chose to improve it, not
delete it. Today conduct audits old work, asks one narrow question, and
nothing acts on what it finds. Plans: C1 moves into the verifier and
plan-checker as prevention; conduct becomes an auditor of the gates (recent,
risky sample; C2 "a fix's test fails without it"; CONCERN feeds retro; rate
visible in dispatch).

## Decisions

- Two plans and two research files: C1 at the gates and the recent, risky
  sample are buildable now; C2 and the retro route have open design
  questions (verifier r1-r6), so they go through research first.

## Rejected

- Deleting conduct: it is the only independent measure of the gates.

## Review

- r1: C2 whole-topic red gives false FINE (verifier) (fixed: C2 moved to research conduct-c2-design, trap listed)
- r2: C2 false CONCERN cases: multi-merge stems, skip(), refactors, unlisted topic (verifier) (fixed: same research, traps listed)
- r3: no single-topic selector; full suite 493 s; step order inverted; runner location unsaid (verifier) (fixed: same research)
- r4: ledger header change outside scope; empty C2 cells dilute the rate (verifier) (fixed: no C2 column in the plan)
- r5: retro sample unit, dedupe key and sampling rule do not fit conduct rows (verifier) (fixed: research conduct-concern-to-retro)
- r6: alarm can keep conduct due back to back; underspecified (verifier) (fixed: alarm out of scope until the research)
- r7: recency window leaves gaps when a run is late (verifier) (fixed: window anchored on the ledger's last landing)
- r8: risk order not buildable as written (verifier) (fixed: three keys, tier read at retire^, plan none last, sha1 tie-break)
- r9: A4 count wrong (verifier) (fixed: assumption rewritten around the pinned needle)
- r10: orchestrated.sh needles outside scope (verifier) (fixed: added to scope)
- r11: A2 evidence command proved nothing (verifier) (fixed: assumption removed with C2)
- r12: acceptance lines lacked expected output (verifier) (fixed)
- r13: c1 grep is line-based and fails on wrapped text (verifier) (fixed: folded grep)
- r14: c1 anchor heading would go stale (verifier) (fixed: anchors "C1 criterion")

## Blockers

None.

## Where to look

- `joharness.sh:conduct_candidates`: the sample sorts all history by hash.

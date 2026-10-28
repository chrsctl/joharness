---
workstream: conduct-c2-design
status: in-progress
branch: research/conduct-c2-design
pr: none
plan: conduct-c2-design
issue: none
session: https://claude.ai/code/session_01J1YMK7QGg4E4RrtuYft1bf
agent: opus
updated: 2026-10-28
next: Retire: delete research file, prototype and workstream file; PR; finish; merge
---

## Goal

Settle docs/research/conduct-c2-design.md: can conduct check, per sampled
branch, that the selftest case a fix added fails on the pre-fix parent,
without false FINE or false CONCERN, at a cost of 3 branches per run.

## Decisions

- Design: T_fix = last retire tree; T_nofix = T_fix with the stem's own
  non-merge commits reverted (3-way) and selftest files restored from T_fix;
  run only the units holding touched topics, read each label's own word.
  Why: tests from T_fix kill the missing-helper and unlisted-topic traps.
- Verdict is per case, read against the Goal: the fixture `other` (an
  unrelated case flips, the fix's own case passes either way) gives a
  mechanical FINE that only the per-case table exposes.

## Rejected

- `git revert` of own commits: conflicts in test files it then discards.
- `git apply -R --3way` of own non-test diffs onto T_fix: conflicts when
  main merged into the branch moved the same lines
  (requirement-partly-served, 970de5c1 against joharness.sh).
- Code from the main commit the branch last merged replaces both reverts;
  `--ancestry-path --first-parent` to find that merge returned nothing for
  guard-one-shot-self-kill (it merged main after its retire): loop instead.

## Review

- r1: `.md` gate calls command-file fixes N/A; 2 of the next sample hidden (verifier) (fixed: gate excludes only docs/handover, plans, research; both stems re-run, FINE)
- r2: determinism claim rested on three different trees (verifier) (fixed: same stem run twice, two stems, tables identical; A1 rewritten)
- r3: plan's 80 s bound contradicts the measured 87 s (verifier) (fixed)
- r4: plan's fixtures drop fx-other, fx-newtopicchar, no chain fixture (verifier) (fixed: fx-chain added and run; all three in the plan's Acceptance)
- r5: two-PR naive cell quotes a different run (verifier) (fixed: cell says what each run shows)
- r6: fixtures.sh built on the source's local main (verifier) (fixed: builds on the source's origin/main)
- r7: "last conduct sample" is the next draw (verifier) (fixed)
- r8: workstream file stale across two commits (verifier) (fixed: this commit)
- r9: plan names a `## C2` heading, shared:joharness.sh scope, open sync choice (verifier) (fixed: paragraph named, scope dropped, canonical-only decided)
- r10: research branch adds code and a plan (verifier) (wontfix: the scripts are deleted at retire, kept in branch history as evidence; the plan is the research file's own YES consequence, manage.md: follow-up work = a plan file in the pull request)
- r11: spawn prompt carried more than the listed fields, base sha moved by a later merge (verifier) (no change: prompt practice, nothing in the diff)

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — runner; no single-topic selector (per Echo).
- `.claude/commands/conduct.md` — graduation target.

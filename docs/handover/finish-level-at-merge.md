---
workstream: finish-level-at-merge
status: in-progress
branch: finish-level-at-merge
pr: none
plan: finish-level-at-merge
issue: none
session: https://claude.ai/code/session_01J1YMK5XJnYWH5pXzz3wazu
agent: opus
updated: 2026-11-12
next: Read ci and verify counts on this head; then verifier at opus, finish, PR
---

## Goal

Under `JOHARNESS_CHECKS=local`, re-measure "0 behind" at the end of `finish`
and at the merge call, so a base that moves mid-run never merges unchecked.

## Decisions

- A1: confirmed — one `fetch` in checks_gate, after the tree refusals, before BEHIND and the suites (plan wording fixed).
- A2: confirmed — checks_outrun prints OUTRUN when green head = HEAD; end check runs after the green write.
- A3: confirmed — certificate writes `base=$tip`, the pinned tip; the end fetch does not touch it.
- HANDOVER_FETCH=0: end check compares the ref as of the last fetch, labelled so (plan-checker r4).
- Built inline, no workers: one function plus one fixture in a shared file, sequential by rule.

## Rejected

- None yet.

## Review

- r1: (plan-checker) acceptance `bash .agents/harness/selftest/checks.sh` not runnable alone, exits 0 (fixed: verify grep for FAIL level:)
- r2: (plan-checker) consumer-repos paragraph heading also turns false (fixed: plan says rewrite the whole paragraph)
- r3: (plan-checker) Goal cites a heading that does not exist (fixed: names the paragraph)
- r4: (plan-checker) HANDOVER_FETCH=0 unspecified at end of run (fixed: compares as of last fetch)
- r5: (plan-checker) "commits to the fixture's origin" ambiguous (fixed: separate clone)
- r6: (plan-checker) end BEHIND after a mid-run branch commit prints NOT OUTRUN (fixed: plan names it as intended)
- r7: (plan-checker) acceptance names no failure form (wontfix: each line carries its expected count)
- r8: (plan-checker) acceptance grep breaks if the pattern wraps (fixed: plan pins it to one line)
- r9: (plan-checker) A1 "before the refusals" inexact (fixed: reworded)
- r10: (plan-checker) consumer-repos headroom understated (no change)
- r11: (plan-checker) its own run of checks.sh left /checksorigin.git and /checkswork at the container root; removal refused by a safety check (wontfix: ephemeral container, outside the repo)

## Blockers

None.

## Where to look

- `joharness.sh:checks_gate` — the single fetch and the certificate write.

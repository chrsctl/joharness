---
workstream: verifier-cannot-read-the-plane
status: in-progress
branch: claude/verifier-cannot-read-the-plane
pr: none
plan: verifier-cannot-read-the-plane
issue: 267
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: sonnet
updated: 2026-10-08
next: Retired with the plan in the last commit before the pull request; merge when checks are green.
---

## Goal

Issue #267, option 1 only: the verifier has Read, Grep, Glob, Bash and no control-plane call, so a claim resting on a reading outside this checkout is one it can only check for internal consistency. Say so in verifier.md, have research nodes name their second context up front in Method, and pin both with one shared literal. Supervised-only plan, supervised session at the human's /drain, 2026-10-08.

## Decisions

- The shared literal is `outside this checkout`, the phrase the plan's
  Scope already uses. `review.sh` pins it against `verifier.md`, then looks
  up in the research README exactly what the first match held — needle
  first, and an empty first match is its own failure, never a pass.
- The verifier MARKS an unreachable claim UNVERIFIED and still reports it:
  arithmetic checked, repository checked for contradiction, the untaken
  reading named. Its tools are unchanged (the plan puts widening them out of
  scope, as the human's call).
- The new assertions carry the same canonical-only guard as the existence
  check beside them: a consumer receives these files and does not own them.

## Rejected

## Review

- r1: (session) proved by `./joharness.sh mutate .claude/agents/verifier.md
  67 ...`, the boundary line reworded, 2026-10-08: baseline green, 2 cases
  red — the boundary assertion and the cross-file comparison, both positive.
  The tool restored the line itself. `ci: pass`, 2300 passed, 0 failed.
  (fixed)
- r2: (verifier) the #267 instance was stated stronger than the record: the
  closed node's `## Verification` opens by saying its reviewer re-sampled
  NOTHING, and what was withdrawn was a cadence spread and a licence, not
  "the answer". (fixed — both files now say what the record says: evidence
  was live session records, the Verification had to open by saying the
  reviewer re-sampled nothing, no reading was confirmed as real)
- r3: (verifier, /code-review) UNVERIFIED was a fourth word beside the
  README's GROUNDED / WEAK / UNGROUNDED, with no mapping. (fixed — UNVERIFIED
  is the reviewer's report word; in a node it is WEAK at best, never
  GROUNDED, said in both files and asserted)
- r4: (/code-review) "no call that reaches a live service" was false: Bash
  can run `gh`, `curl`, `git fetch` where the container allows. (fixed — the
  limit is stated as what it is: this checkout and commands in this
  container, NO control-plane call, so a session record above all)
- r5: (verifier, /code-review) the "SAME boundary" check was circular: its
  token came from grepping the literal itself. (fixed — the token is read
  from one MARKED line in verifier.md, pinned to the literal by the first
  check and looked up in the README by the second; a reword on either side
  alone reds)
- r6: (/code-review) `issue: none` while the work is #267's option 1 — the
  hook would show #267 free. (fixed — `issue: 267`)
- r7: (/code-review) `next:` named work already done in the commit that
  also edited this file. (fixed)
- r8: (/code-review) the canonical guard was copied, and the new block sat
  between `out="$(jr review)"` and the five checks reading it. (fixed — one
  `rv_canon`, the block moved below those checks)
- r9: (/code-review) a short needle checked over the whole file could survive
  the section's deletion if the phrase appeared elsewhere. (fixed by r5: the
  token comes from the one marked line, and "best, never GROUNDED" and the
  UNVERIFIED line are pinned beside it)
- r10: (session) re-proved after r5 by `./joharness.sh mutate
  .claude/agents/verifier.md 71`, the marked line reworded to `beyond this
  repository`, 2026-10-08: baseline green, 2 red — the literal pin, and the
  README comparison on a REAL token this time (not the empty branch). Tool
  restored the line. `ci: pass`, 2301 passed, 0 failed. (fixed)

## Blockers

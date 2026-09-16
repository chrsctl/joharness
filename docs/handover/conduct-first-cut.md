---
workstream: conduct-first-cut
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: 251
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Review the plan, retire this file, open the pull request
---

## Goal

Issue #251 asks for a periodic sampling review of a manager's CONDUCT — the
questions the verifier (which reads the diff) and the health pass (which
reads the pulse) structurally cannot answer. The issue ends by NOT claiming
the cost is worth it, and its shape is a session beyond the cap, which is
money.

Decomposing it is the work (Loop step 2). This branch adds one plan and no
code: the single conduct question that needs no session, no sampling, no cap
and no money, because it is answerable from git alone. The rest of #251 waits
on the cost decision, which is the human's.

## Decisions

- Deliver the PLAN, not the build. `.agents/docs/plans/README.md` names this
  shape: a pull request adding only the plan puts it in the queue. The build
  then goes to a session at the tier the plan sets, which is how an issue is
  supposed to reach code.
- The question picked is "were findings recorded BEFORE the fix and in the
  same commit", one of the five #251 lists. It is the only one decidable from
  commit order alone — no control-plane read, no second session, no sampling
  rate to calibrate, so none of the issue's own cost caveat applies to it.
- Chosen partly because this session BROKE it: finding r16 on the branch that
  merged as `#253` records findings written after their fixes and left
  uncommitted, caught by a verifier rather than by any gate. The rule has a
  live counter-example in this week's history.
- `ci` already carries two lints over this branch's findings — one report-only
  and one that reds — so the new one has a home, a pattern and a precedent
  for which strength to pick.

## Rejected

- Building the check on this branch. A lint that reds is a lint that can red
  somebody else's branch wrongly, and its false-positive shape (a wontfix
  touching nothing else, a fix legitimately split across commits) needs the
  design attention a plan exists to buy. Filing it as a plan is not deferral,
  it is the decomposition the Loop asks for.
- Taking #249's remainder. Its two halves are the scheduler, which is the
  human's, and the research node this session filed, which is queue work of
  its own and older-ranked behind the free plan.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:lint_finding_ids` and `lint_finding_markers` — the two
  existing finding lints, and the report-versus-red precedent.

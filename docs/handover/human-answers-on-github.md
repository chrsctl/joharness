---
workstream: human-answers-on-github
status: in-progress
branch: claude/human-answers-on-github
pr: none
plan: human-answers-on-github
issue: none
session: https://claude.ai/code/session_01J1YMK6L8MbE3uRqJ6F9WyS
agent: opus
updated: 2026-11-11
next: Run ci and verify on the rewritten docs and pins, then verifier, walk-through, PR
---

## Goal

A human reads a question and answers or approves it, on GitHub, with one
gesture, whoever asked: `human-review` stays the one hold label, a
`decision needed:` comment makes it a question, approve or a reply answers it.

## Decisions

- A1: confirmed — `grep -n "human-review\|approved" joharness.sh` hits only the scout-reviewer conf line, scout status prints and the `human/<stem>` banner in `cmd_session_start`; no gate.
- A2: confirmed — `./joharness.sh protocol-paths` prints joharness.conf, .claude/settings.json, .github; no scoped file is one.
- A3: confirmed as stated — clerk.md THE SCOUT GATE already rests on it; GitHub docs not re-read (no change to trust).
- A4: confirmed as stated — this session's own commits push as the maintainer login; not re-read on GitHub.
- manager.md has 46 bytes of reading budget: its block mechanics move to a new manager-reference § Question, the bound is not raised.

## Review

- r1: (plan-checker) manager.md 46 bytes under its reading budget; the §3 edit would red `ci` (fixed: Scope moves the mechanics to manager-reference § Question, trap added)
- r2: (plan-checker) scout trigger and scout.md §3 skip approved issues, so a revision on an approved proposal never runs (fixed: Goal 6 scout-trigger line, Scope names both)
- r3: (plan-checker) clerk skip bullet "newest counting comment is a clerk verdict" not amended (fixed: Scope gives it the same exception)
- r4: (plan-checker) second firing rule silent on planned/claimed; Goal 6 split on who acts for a plan's issue (fixed: exclusions hold, planned/claimed issue = § Relay only)
- r5: (plan-checker) an answer to a clerk question on a scout proposal fires scout trigger (i); item 1 halves unclear (fixed: comment newer than an open clerk question is the clerk's; label half only)
- r6: (plan-checker) pin-count acceptance passes on net +1 and prints nothing on failure (fixed: `-ge o+3`, prints `fewer`)
- r7: (plan-checker) "new pins fail on today's text" has no acceptance command (fixed: worktree command added)
- r8: (plan-checker) acceptance items without today's value (fixed: values added)
- r9: (plan-checker) SHIPS item not runnable (fixed: marked not a command)
- r10: (plan-checker) README and orchestrator-reference Scope never ask for `decision needed:` (fixed: both Scope items name it)
- r11: (plan-checker) "so the next pass reads it" anchor matches twice (fixed: Scope says the new pin's needle must not match the DOES NOT HOLD line)
- r12: (plan-checker) dispatch.sh pins § Label at merge commands (fixed: Scope and trap keep them verbatim)
- r13: (plan-checker) A1 names `cmd_role` for the `cmd_session_start` message (fixed)
- r15: (plan-checker) round 2: pin-fail acceptance counts FAIL lines twice plus the header (fixed: matched by pin name, `all-fail`)
- r16: (plan-checker) harness AGENTS.md keeps "never remove it" (fixed: Scope replaces it)
- r17: (plan-checker) orchestrator.md blocked row never reaches § Relay for a GitHub answer (fixed: added to scope)
- r18: (plan-checker) "a `decision needed:` comment" vs the clerk's second line; who may carry `answered:` (fixed: first two lines; footed write-access comment)
- r19: (plan-checker) label/comment order unstated; label first can freeze for good (fixed: comment first, then label)
- r20: (plan-checker) manager question onto an item already labelled (fixed: none there, its answer resumes nothing)
- r21: (plan-checker) scout trigger's "An approved or planned issue waits on the clerk" left (fixed: Scope rewrites it)
- r22: (plan-checker) defect issue filed for a human plus a manager block = two questions (fixed: that issue is the one item)
- r23: (plan-checker) freeze `next:` wording claimed pinned by dispatch.sh (fixed: claim dropped)
- r24: (plan-checker) walk-through and SHIPS items not commands (no change: marked not a command; the verifier checks the walk-through)
- r25: (plan-checker) selftest-fail-stderr plan may change the FAIL format the acceptance parses (no change: matched by pin name after `FAIL `, its plan keeps counts)
- r14: (plan-checker) A3, A4 and gx history not checked against GitHub (no change: recorded as stated, no rule rests on re-reading them)

## Blockers

None.

## Where to look

- `docs/plans/human-answers-on-github.md` — the plan, Scope lists every file.

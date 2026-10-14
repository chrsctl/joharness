---
workstream: human-follow-ups-die-at-retire
status: in-progress
branch: claude/human-follow-ups-die-at-retire-7k2q
pr: none
plan: human-follow-ups-die-at-retire
issue: none
session: https://claude.ai/code/session_016spQNSNiq2i68P9xyAwCPe
agent: fable
updated: 2026-10-14
next: Run ci and verify, spawn the verifier at fable, record the review, retire the research and workstream files, open the pull request, merge
---

## Goal

Settle `docs/research/human-follow-ups-die-at-retire.md`: does the harness
give a manager a durable place to leave work only a human can do (a
core-path edit), or does that work survive only in a merged pull request's
body? Graduate the answer into `.claude/commands/manage.md` and delete the
research file.

## Decisions

- Settled YES. Home for a human remainder = one GitHub issue labelled
  `human-review`, filed by the manager before its retire commit. Chosen
  because the clerk already holds and lists such issues every pass, the
  human's merge closes it, and issues are the front door for human asks.
- Graduation is text only: manage.md §2, a why-section in
  `.agents/docs/plans/README.md`, one clause in orchestrated.md Bounds. No
  plan filed: no code changes.
- Second context taken in a fresh read-only clone of `chrsctl/gx`
  (`add_repo`, `git clone --depth 1`, `fetch --depth=400`). One finding
  corrected: instance 2 was closed by gx #656 before its plan merged.

## Rejected

- A ledger file on `main` (`docs/human-followups.md`): a row the human's
  `.github` merge forgets to delete is stale state, and dispatch reading it
  is the stored-copy failure graph.md forbids.
- Lifting the core-only red so the remainder stays a plan: that is the
  sibling research `partly-core-plans-strand-their-slots`'s ground, and a
  plan nobody spawns on sits until a human notices (pull request #457).
- A `dispatch` change counting `human-review` issues: dispatch reads git
  only today; left open, named in the README section.

## Review

One bullet per finding, written BEFORE its fix, committed WITH it, in exactly
the form `- rN: text (fixed|wontfix: why|no change)` — `ci` checks it. Tag the
verifier's findings `(verifier)`. Clean pass = one bullet saying so. Remove
this paragraph when you add the first bullet.

## Blockers

None.

## Where to look

- `.claude/commands/manage.md` — the follow-up sentence the answer graduates into.
- `.agents/docs/plans/README.md` — the CORE ONLY paragraph the sentence collides with.

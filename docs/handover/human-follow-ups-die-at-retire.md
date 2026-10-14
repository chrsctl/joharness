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
next: Re-run ci alone (r9), then retire the research and workstream files, open the pull request, merge
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

- r1: (verifier) `Closes #N` in the manager's own body closes the remainder issue at that merge, before any human edit (fixed — `Refs #N` in manage.md §2 and the README section; `Closes` is the human's)
- r2: (verifier) side finding cited `88c820fd`'s message, which says nothing of the human's order; gx #655's body does (fixed — pointer names the pull request body)
- r3: (verifier) UNVERIFIED used as a node mark; the vocabulary is GROUNDED, WEAK, UNGROUNDED (fixed — WEAK)
- r4: (verifier) manage.md paragraph stated the why twice, already in the README section (fixed — trimmed to the rule, README holds the why)
- r5: (verifier) trigger named a `## Human follow-up` heading no template defines (fixed — any core-path edit the plan leaves to a human, under whatever heading)
- r6: (verifier) §4 Finish did not point at the issue step a manager resuming from `next:` needs (fixed — §4 "Before the retire commit" names it)
- r7: `./joharness.sh ci` 2026-10-14, first run: 2807 passed, 1 failed — the 80 KB prose-keyword timing case at 6s (wanted <= 4s) while `verify` and the verifier's own `ci` ran beside it; the verifier's run on the same tree: pass (no change — re-run alone after the fixes, r9)
- r8: `./joharness.sh verify` 2026-10-14: 4 passed, 2 failed, both container egress through the sandbox proxy (alpine:3 pull, HTTPS from a container); this diff is `.md` only, so step 7 does not require it; GitHub's run of the layer is read at merge (no change)

## Blockers

None.

## Where to look

- `.claude/commands/manage.md` — the follow-up sentence the answer graduates into.
- `.agents/docs/plans/README.md` — the CORE ONLY paragraph the sentence collides with.

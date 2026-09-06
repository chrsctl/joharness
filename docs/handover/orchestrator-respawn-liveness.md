---
workstream: orchestrator-respawn-liveness
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: orchestrator-respawn-liveness
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-06
next: Amend the health table in orchestrate.md, mirror it in orchestrated.md, then run the three-way discrimination check
---

## Goal

The health table's respawn row reads `not RUNNING` as *session gone* and
spends a manager on ONE observation. The control plane's IDLE means BETWEEN
TURNS, so `not RUNNING` selects working sessions — and every manager in run 1
that armed its own check-in read IDLE for the whole interval. The kill row
beside it demands two signals, a nudge and a confirming pass; a session
between turns was therefore cheaper to replace than one that had genuinely
stopped. Consumer `chrsctl/gx`, 2026-09-06: one duplicate manager, ~17 USD,
against a session that woke at 17:41Z and merged its own pull request.

A third state rides along: a CRASHED session also reads `not RUNNING`, and
fixing the IDLE row alone makes a crash strictly worse — a dead session would
then be sent a nudge nothing is listening to.

## Decisions

- Written for the literal reader, because that is the failure mode: the
  orchestrator of run 1 had refused this exact inference at 13:22Z by
  reasoning past the text, and followed it at 17:13Z. A rule that needs the
  reader to override it is the defect, so the fix is prose that gives the
  same answer to a reader who does not think.
- The table is keyed on FIELDS now, not on the phrase "not RUNNING". That
  phrase is what let one field decide liveness; the plan's own point is that
  the control plane has at least five states across three fields.
- The rows I added last item (`PR in flight, no claim file`) carried the same
  `not RUNNING` defect and are fixed in the same pass. Half-applying the fix
  inside one table is how the next reader picks the wrong half.
- The "no `interrupt_session`" degradation rule is scoped to a session that
  may still be RUNNING. Read unscoped, it forbids respawning a CONFIRMED DEAD
  session — the rule against two sessions on one branch, applied where there
  is only one.

## The discrimination check (the plan's Acceptance, run)

Four fresh low-tier sessions, each given ONLY the table text — no repository,
no plan, no tools — plus ONE observation, asked what it does. Three of the
four readings were disguised (different stem, sha, timestamps) so a reader
could not pattern-match the worked example. 2026-09-06:

| text | observation | answered |
| --- | --- | --- |
| `origin/main`'s | IDLE, `completed`, pull request open, head not an ancestor | **RESPAWN** — quoting the `not RUNNING … session gone` row verbatim. The 17 USD defect, reproduced on demand. |
| amended | same shape, disguised, `status_bucket` OK | **NUDGE**, quoting the IDLE row |
| amended | crash shape, disguised, `status_bucket` FAILED | **no nudge**; ledger it, and archive-then-respawn next pass if the record and head are still frozen |
| IDLE fix only, FAILED rows removed | that same crash shape | **NUDGE** — the wrong answer, a nudge sent to something that cannot answer |

Three versions, three different answers on the same input, which is what the
plan asked the check to discriminate. The fourth row is why the FAILED rows
are not decoration: without them the IDLE fix alone makes a crash worse.

## Rejected

- **Removing IDLE from the table's vocabulary and leaving the respawn row
  otherwise intact** — the plan's own first Trap. The missing nudge is half
  the defect: any single-observation respawn spends a manager on a guess.
- **Keying the crash row on `post_turn_summary.status_category: failed`.**
  It is the session's own account of its turn, and it is the same field that
  said `completed` over an unmerged head at 17:13Z. `status_bucket` is the
  control plane's, and only that may decide liveness.

## Review

Pending — edge review at step 5 (opus: adversarial, separate lenses, plus
`verifier`), and the plan's own discrimination check: hand a session ONLY the
amended table plus run 1's two readings and require nudge / confirm-then-
respawn respectively. Old text answers respawn to both, so the check can fail.

## Blockers

None here. Consumer-side acceptance (this plan SHIPS) has a cheap version the
plan itself names, which runs on a session rather than a fleet; the full
version needs a consumer fleet this session cannot reach.

## Where to look

- `.claude/commands/orchestrate.md` — the health table and the KILL sequence
  under it (the nudge-then-confirm pattern to copy).
- `.agents/docs/orchestrated.md` — the second copy of the same table.

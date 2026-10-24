---
research: human-merge-does-not-wake-blocked-manager
urgency: normal
agent: sonnet
effort: medium
graduates: .claude/commands/manage.md
---

## Question

When a plan's own acceptance requires a human to merge a `human/<stem>` pull request before the plan's pull request, does anything wake the blocked manager (or re-dispatch the item) when that merge happens?

## Echo

A manager that builds everything but must wait on a human-merged core-path PR blocks (`status: blocked`, `next: core path: …`), exits, and "is never respawned" (manage.md §3). Asked whether the merge of the human PR is itself a wake signal, or only a human message is.

## Sweep

`goal-directed`: the one edge below, and the two harness rules it ran under (manage.md §2 human remainder, §3 contract).

## What would settle it

Settled "no": a merged human PR and no manager/orchestrator activity until a human wrote to the session. Settled "yes": dispatch or the orchestrator re-dispatching the item, or a notification reaching the session, after the merge and before any human message.

## Method

Reported from consumer repo `chrsctl/gx`, edge `rename-runsvc-runner` (merge `2aa839292`, PR #892; human PR #866 on `human/rename-runsvc-runner`). `./joharness.sh upstream rename-runsvc-runner` printed `NOTHING TO REPORT` (all 6 recorded findings were on the consumer's own files), so this was filed by hand on the user's instruction. Not measured: orchestrate.md / `dispatch` behaviour. I did not read them.

## Findings

- **A manager blocked on a human-merge prerequisite stayed blocked after the prerequisite merged, until the human wrote to the session.** Timeline: manager session pushed `status: blocked`, `next: core path: merge human PR #866 …` and exited with PR #866 open and labelled `human-review`; the manager had not opened its own PR. The user then reported the merges in chat ("All merged", and later "Both pr were merged that should have triggered"), and only that message resumed the item. The resumed session found `.github/workflows/ci.yml` already carrying the change (`grep -c runsvc .github/workflows/ci.yml` → 0) and finished in one pass (merge `origin/main`, `run-all.sh` 29/29, `./joharness.sh ci` pass, PR #892 merged 2026-10-24T12:06+02:00).
- **The block was the rule-correct move, so the gap is in the design, not the session.** manage.md §3: a blocked item "is never respawned" and a manager never waits in session; the plan (`rename-runsvc-runner`) required the human PR "before this plan's pull request". Nothing in the rules the manager reads names the PR merge as the unblock signal; `next:` is free text.
- **Cost of the gap here:** one human relay message per blocked item, plus a 180-commit-behind branch (a stale tree) that the resumed session had to merge. Another change on `main` anticipated the rename (`scripts/crm-all.sh` carried a fallback for both directory names), so the delay also left a live dead-code fallback to clean up.

## Consequence for the queue

If dispatch/orchestrate does not already treat "the PR named in a `core path:` block merged" as re-dispatchable, manage.md §3 (and the `next:` grammar `block_reason_ok` accepts) should let a block name the awaited PR (e.g. `core path: waiting on #866`) and dispatch should list the item as resumable once that PR is merged. If it already does, this is a defect in that detection: the item was not re-dispatched. Which of the two holds is not measured here.

## Verification

Not yet verified by a second context. Claims about the timeline are GROUNDED in the consumer's git history and PR records (#866, #892); the claim about orchestrator behaviour is UNGROUNDED (not read).

## Graduates to

`.claude/commands/manage.md` § 3: the block grammar is where the awaited PR would be named.

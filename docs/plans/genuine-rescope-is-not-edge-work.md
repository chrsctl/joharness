---
plan: genuine-rescope-is-not-edge-work
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: 492
scope: .agents/harness/handover-context.sh, .agents/harness/selftest/handover-context-rank.sh, joharness.sh, .agents/harness/selftest/dispatch.sh, .claude/commands/orchestrate.md, .agents/docs/handover/README.md
---

## Goal

A surveyor that finds the holds GENUINE ends as `.claude/commands/manage.md`
(rescope) tells it to: `status: done`, `pr: none`, `plan: none`, no pull
request, exit. Nothing on that branch is ever merged. Three readers still
treat it as live work, so the orchestrator nudges the idle surveyor every
pass, each reply moves `updated_at`, the nudge record is dropped, and the
next pass nudges again (issue #492; seen 2026-10-14 on
`origin/rescope-dispatch-names-the-core-wait`: four orchestrator sessions,
more than six nudges, no progress possible):

1. the session-start hook ranks it rank 0, prints `EDGE:` and may make it the
   `FINISH BEFORE STARTING` lead, which `cmd_dispatch` turns into its
   `edge work` section;
2. `cmd_dispatch` lists it under `rescope branch(es) in flight:` like a live
   surveyor (it already counts it as settling the key — keep that);
3. `.claude/commands/orchestrate.md` drops a ledger entry only when the branch
   merged, which a genuine rescope never does, so the `rescope-<key>@…` entry
   stays and the `IDLE/PENDING | branch unmerged, no nudge` row nudges again.

Fix by the issue's option 1: such a claim is FINISHED — no edge, holds no
slot, never nudged — and still counts as rescoped for its key so no new
surveyor spawns.

"Finished rescope" below = a workstream file whose `workstream:` starts
`rescope-`, with `plan: none`, `status: done`, and `pr:` empty or `none`. All
four conditions; anything else keeps today's behaviour.

## Scope

- `.agents/harness/handover-context.sh` — a finished rescope gets no `EDGE:`
  line and is never the `FINISH BEFORE STARTING` lead. It still prints in the
  branch list, with one line saying it is a finished rescope that holds
  nothing. Give it a rank that does not read as live work: NOT 3 (the
  default, "building") — use a dedicated value at or below `blocked` (4) or
  next to `abandoned` (5), your call, recorded in the workstream file. Fetch
  `workstream` and `plan` beside the existing `fields` read.
- `joharness.sh` (`cmd_dispatch`, rescope block) — a finished rescope's row
  under `rescope branch(es) in flight:` says so: e.g. `done: finished
  rescope, holds no slot — never nudge`, the way the `free-` loop's `done:
  holds no slot` row does. It still settles the key (`rescope_settled=1`).
- `.claude/commands/orchestrate.md` (health table) — one rule: a
  `rescope-<key>` ledger entry whose dispatch row reads finished (the text
  above) is done: drop the entry, keep `rescoped=<key>`, nudge nothing,
  respawn nothing. Placed so it wins over the `IDLE/PENDING | branch
  unmerged, no nudge` row.
- `.agents/harness/selftest/handover-context-rank.sh`,
  `.agents/harness/selftest/dispatch.sh` — the cases below.
- `.agents/docs/handover/README.md` — the rank section says rank reads two
  fields and makes `status: done`, unmerged rank 0: add the finished-rescope
  exception in the same place. While there, its `joharness.sh:at_edge`
  reference names a function that does not exist; the function is
  `review_at_edge` — fix that one word.

## Out of scope

- A new status word, or any change to `manage.md`'s genuine path (option 2 of
  the issue: rejected — option 1 needs no new vocabulary and keeps the
  surveyor's record on its branch).
- `janitor` and `HANDOVER_STALE_SECONDS`: the 144h window stays.
- Other docs that define "edge" as `status: review/done` in general
  (`.agents/harness/AGENTS.md` Loop step 2, `.agents/harness/queue-context.sh`,
  `.agents/docs/agent-selection.md`): a finished rescope has no plan, so those
  readers never meet it. Leave them.
- Deleting `rescope-dispatch-names-the-core-wait`: human-only
  (`git push --delete`).
- A `rescope-*` claim with `pr:` set, `status: review`, `in-progress` or
  `blocked`: unchanged.

## Acceptance

Runner: `.agents/harness/selftest.sh` (all topics; there is no
`./joharness.sh selftest` subcommand and topic files do not run alone) or
`./joharness.sh ci`, which runs it.

- `handover-context-rank.sh`, new assertions, all passing:
  - a branch whose `docs/handover/rescope-k.md` is a finished rescope gives no
    `FINISH BEFORE STARTING` line naming it and no `EDGE:` line under it;
  - the same file with `status: in-progress` still lists exactly as today;
  - the same file with `status: done` and `pr: 12` is still edge work;
  - the existing `bdone` case stays green unchanged. Fixture branches added
    here must not take the lead from `bdone`: give them newer push dates, or
    their own fixture repo. `rankbranch` writes no `plan:`/`workstream:` and
    the order sed matches `[a-z]*` only — extend the helper or write the
    fixture by hand; do not loosen an existing assertion.
- `dispatch.sh`, in the existing rescope fixture (`claude/rescope-keeper`):
  the done case still asserts `a rescope for this key is done or blocked`,
  `refute` `spawn ONE surveyor`, `refute` `a surveyor is already in flight`,
  and now also asserts the finished-rescope row text; and no `edge work`
  section names the branch.
- With the fix reverted, the new hook assertion and the new dispatch assertion
  each FAIL; record both failing outputs in the workstream file's `## Review`.
- `./joharness.sh ci` — `ci: pass`; `./joharness.sh verify` — `0 failed`.
- Consumer-side: the diff ships (`ci`'s ship-scope stage names
  `.agents/harness/handover-context.sh`). The check a consumer runs is the
  same `.agents/harness/selftest.sh` its `./joharness.sh ci` runs after sync:
  the new assertions live in the shipped selftest files, not a canonical-only
  test. Say so in the pull request body.

## Where to look

- `.agents/harness/handover-context.sh:rank_of` — maps `done` to rank 0; the
  exception belongs where the row is ranked.
- `.agents/harness/handover-context.sh:lead_why` — a variable; the lead text
  `status done and unmerged`. `cmd_dispatch` greps the line PREFIX
  `FINISH BEFORE STARTING:`, not this phrase — rewording alone changes
  nothing in dispatch.
- `joharness.sh:cmd_dispatch` — the `edge` capture from the hook, the
  `rescope_inflight` loop over `dispatch_rescope_branches`, and the `free-`
  loop's `done: holds no slot` row to mirror.
- `joharness.sh:dispatch_rescope_branches` — returns branch, key, status,
  session, next; it does not read `pr:` today — add it if the row needs it.
- `.agents/harness/selftest/dispatch.sh:rb` — the rescope fixture's runner;
  the `claude/rescope-keeper` done case.
- `.agents/harness/selftest/handover-context-rank.sh:rankbranch` — fixture
  helper; the `bdone` case.
- `.claude/commands/orchestrate.md` — health table rows "branch merged
  (dispatch no longer lists it)", "a nudge … moved since", "IDLE/PENDING …
  branch unmerged, no nudge".
- `.claude/commands/manage.md` — rescope, "Nothing to change = the holds are
  GENUINE".

## Traps

- NEVER skip, disable or quarantine a test to get green; never loosen an
  existing assertion to fit.
- Each test for the fix must FAIL without it.
- Hiding a LIVE surveyor is the wrong-but-plausible bug: match all four
  conditions (prefix, `plan: none`, `status: done`, no `pr:`).
- Workstream text on another branch is repo-controlled input: compare exact
  words, never eval it; keep `cmd_dispatch`'s status allow-list.
- No commit to a core path (`./joharness.sh protocol-paths`).

---
research: retired-branch-holds-slot-past-refused-merge
urgency: normal
agent: sonnet
effort: medium
graduates: .claude/commands/orchestrate.md
---

## Question

Does `dispatch` count a slot for a retired branch whose pull request is open
and ready, but whose manager's merge was refused by its own permission
policy, when no row of the orchestrate health table can ever free that slot?

## Echo

A retired branch with no claim file holds a slot until its merge lands. The
health table has one row for that state, `RUNNING | retired, no claim file |
merging; nothing`, and one for a gone session (respawn to finish the merge).
Neither row covers an IDLE session that tried to merge and was refused. If
the slot is then held indefinitely, `dispatch` states "commits a slot" as if
work were under way, when the only thing that frees it is a human.

## Sweep

`goal-directed`: the one consumer run that measured it (chrsctl/gx,
orchestrator session_0132SwBkvDE4dAUiXcUdhaJF, 2026-10-14 to 2026-10-15),
plus the canonical text it ran against.

## What would settle it

Either a health-table row that names IDLE, retired, PR open and merge refused,
and says what to do, which would make this a consumer-side misread, or none.
For the slot, either the dispatch count releasing it, or it staying held
across passes with no change in state.

## Method

- `./joharness.sh dispatch` in chrsctl/gx every ~10 min, passes 80-108.
- `grep -n "retired" .claude/commands/orchestrate.md` (harness=c6e2139e6144).
- `grep -n "retired, no claim file" joharness.sh` (line 6596).
- Control plane: `get_session` / `list_events` on the manager session.

## Findings

- **The slot stayed held for at least 7 hours by direct measurement, about
  15 hours by dispatch age, with no state change.** `canvas-builder-design`,
  branch `claude/canvas-builder-design`, PR chrsctl/gx#714. Dispatch printed
  `retired  pushed 8h ... retired, no claim file` at pass 80 (2026-10-15
  02:45Z) and `pushed 15h` at pass 108 (09:46Z). That is 29 consecutive
  passes counting it as 1 of `JOHARNESS_MAX_MANAGERS=4`, so 25% of fleet
  capacity was idle for the whole window while 32-37 free items waited.
- **The manager did run step 7 and was refused.** Its own runtime refused
  the merge call as "Merge Without Review". The session went IDLE with the
  PR open and ready, and it was reported to the human at 2026-10-14 18:39Z.
  Nothing the orchestrator can send changes that: a nudge produces the same
  refusal, and a respawn inherits the same policy.
- **No health-table row covers it.** `orchestrate.md` has
  `RUNNING | retired, no claim file | merging; nothing` and `gone | edge row
  naming an item | RESPAWN to FINISH the merge`. An IDLE session with a
  refused merge matches neither. The orchestrator therefore reported it
  every pass and acted on nothing, which was correct and changed nothing.
- **The dispatch row's own wording admits the blind spot.**
  `joharness.sh:6596`: "a pull request is expected; this reader cannot see
  one". The PR existed and was open the whole time, so the fact the row
  prints (expected, unseen) is not what was true (open, ready, waiting on a
  human merge).

Dropped: none.

## Consequence for the queue

`.claude/commands/orchestrate.md` health table: add a row for
`IDLE | retired, no claim file | merge refused or PR waiting on a human`.
Suggested shape: report once, ledger `held-human=<pr>`, and stop counting
the slot, the way a `blocked` workstream holds none. Optionally, `dispatch`
could read the PR's state, if the runtime can see it, instead of printing
"cannot see one". Canonical decides. This is a report from a consumer.

## Verification

Second context: session_01MExUnxiQsHtpQxj66zQfMQ (joharness, not the gx
orchestrator that wrote the findings), re-taking readings with GitHub
`pull_request_read` on chrsctl/gx and Claude Code Remote `get_session`.

- PR open and ready: GROUNDED. gx #714 `state: open`, not draft, not merged,
  last updated 2026-10-14T18:36Z.
- Merge refused, session parked: GROUNDED. session_017Gkumd… (manage
  canvas-builder-design) status IDLE, `status_bucket` BLOCKED,
  `status_category` need_input, `status_detail` "PR #714 synced and green;
  merge blocked by permission", `needs_action` "merge ... or grant merge
  permission for this session". Exact refusal wording "Merge Without
  Review": UNVERIFIED, transcript not re-read.
- No row covers it: GROUNDED. Re-take: `grep -n 'retired, no claim file'
  .claude/commands/orchestrate.md` names one RUNNING row; the `gone` edge row
  needs ARCHIVED or not found. The IDLE/PENDING `branch unmerged` nudge rows
  could also match; a nudge-then-RESPAWN there inherits the same policy.
- Dispatch wording: GROUNDED, line moved. `grep -n 'cannot see one'
  joharness.sh` now hits line 6608, not 6596; selftest
  `.agents/harness/selftest/dispatch.sh` asserts the string.
- 29 passes and 7h/15h figures: UNVERIFIED, orchestrator transcript not
  re-read; consistent with PR #714 untouched since 18:36Z.

Corrections change no conclusion: the consequence stands.

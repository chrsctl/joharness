---
workstream: merge-notice-reach
status: in-progress
branch: claude/address-issue-45qgw6
pr: none
plan: docs/plans/merge-notice-reach.md
issue: #230
session: https://claude.ai/code/session_01PsTd99XdX46dYkgMn6mAWt
agent: opus
updated: 2026-09-11
next: verify, then the verifier pass, then retire and open the pull request
---

## Goal

Issue #230, filed from consumer `chrsctl/gx` by the manager that hit it. A
manager finished its item, tried to send `"merged replay-age"` to its
orchestrator, and was refused twice. The human who read the report asked for
the fix here rather than in the consumer, which is also where the harness says
it goes: `.claude/commands/` syncs from this repo, so the consumer's copy is
not editable on its own.

## Decisions

- Same-session plan: written on this branch, retired by this pull request. The
  ask arrived direct from a human and the queue rule is that nothing builds
  unplanned; a small ask is still a small plan.
- Address by the name `ListAgents` gives the caller in its opening line, not by
  session title. The title was refused too, but for want of a route — that
  measurement says nothing about whether a title is an address, and writing
  protocol text on an unmeasured inference is what this issue is about.
- The gate is `ListAgents`, not `ToolSearch`. SUPERSEDES this branch's first
  ruling ("the gate stays `ToolSearch`, with the limit stated rather than
  replaced"), which was right that no probe can predict the MANAGER's peer
  visibility and wrong about what the gate is for: the fixed text has to WRITE
  an address, and `ToolSearch` finding a tool hands the orchestrator no name to
  write. `ListAgents` is one pre-spawn call that yields both — its opening line
  names the caller, and the issue quotes that line. No probe invented: the
  orchestrator's own name is readable from its own container; the manager's
  reachability still is not, and the text still says so.
- Taken over from an abandoned branch, not restarted. `claude/merge-notice-reach-79e466`
  carried both text edits and one recorded finding, and its session is ARCHIVED
  with `status_category: failed` — a dead claim, so step 2 makes it takeable.
  Both commits cherry-picked onto this branch rather than rewritten, which keeps
  r1 attached to the fix it describes; that branch was 87 behind `main` and its
  own `next:` line was stale (it said "make the two text edits", which its
  second commit had already made).

## Rejected

- Editing the consumer's copy in `chrsctl/gx`. It is under
  `./joharness.sh protocol-paths` there, its mode is orchestrated, and
  `AGENTS.md` says a harness fix lands here first — a consumer-only edit goes
  AHEAD on every future sync.
- Dropping the merge line entirely. It costs nothing when it fails and the
  early wake is real where sessions do see each other; the failure is that
  nobody could tell why it failed.
- Claiming cloud-to-cloud messaging never works. What was measured is one
  container listing no peers. `ListAgents` documents a route that exists when
  Remote Control is connected, and a "never" here would be the same unmeasured
  confidence the issue reports.

## Review

- r1: this plan's own first acceptance criterion, `grep -c "session id"` = `0`,
  could never pass — the fixed text has to NAME the form it bans, so the
  string survives the fix by construction (2 hits, both in the new prose:
  `orchestrate.md:304` the prohibition, `:316` the measurement). Written to
  fail, in the plan for a fix about checks that cannot tell a state from its
  absence. Replaced with the phrase the spawn block actually handed a manager,
  `message session <your session`, which is `0` after the edit and was `1`
  before. (fixed)
- r2: the spawn block told the orchestrator to write
  `"<your ListAgents name>"` while its gate stayed `ToolSearch("+SendMessage")`
  — and NOTHING in `orchestrate.md` calls `ListAgents` for the orchestrator's
  own row (`grep -n ListAgents .claude/commands/orchestrate.md`: 24, 40, 149,
  and the merge line itself; the first three are about the TARGET's row). So
  the fix traded an address `SendMessage` refuses for one the caller cannot
  obtain, and a literal reader would have to guess the string. Gate changed to
  `ListAgents`, which yields the name and the tool in one call. (fixed)
- r3: same block said the name form holds "here as at the NUDGE row
  below". NUDGE is `orchestrate.md:149`, the merge line `:412` — above, not
  below. A reader sent the wrong way to check the one cross-reference the
  argument rests on. (fixed)

## Blockers

None.

## Where to look

- `docs/plans/merge-notice-reach.md` — scope, acceptance, traps.
- `.claude/commands/orchestrate.md`, `create_session` bullet and the NUDGE row.
- `.claude/commands/manage.md`, section 4 Finish.

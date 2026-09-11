---
workstream: merge-notice-reach
status: done
branch: claude/address-issue-45qgw6
pr: none
plan: docs/plans/merge-notice-reach.md
issue: #230
session: https://claude.ai/code/session_01PsTd99XdX46dYkgMn6mAWt
agent: opus
updated: 2026-09-11
next: none — retired with the pull request that carries the fix
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
- Escalated sonnet (the plan's `agent:`) to opus, recorded here because
  `.agents/docs/agent-selection.md` requires the reason in this file: the work
  is protocol text whose defect class is a literal reader mis-walking a closed
  set, the exact thing the earlier session got wrong twice, and the tier also
  sets review depth to adversarial. Escalation only; never a downgrade.
- Graduated before retiring, per `.agents/docs/feedback.md` ("file keeps
  drawing findings = rule nobody wrote yet"): `.agents/docs/orchestrated.md`
  now carries "a tool is not a route, and the gate must read the thing it
  claims", with both occurrences on this one line — PR218 r3 and #230 — as its
  evidence. Two rounds on one sentence is the measurement that earns it.
- Taken over from an abandoned branch, not restarted. `claude/merge-notice-reach-79e466`
  carried both text edits and one recorded finding, and its session is ARCHIVED
  with `status_category: failed` — a dead claim, so step 2 makes it takeable.
  Both commits cherry-picked onto this branch rather than rewritten, which keeps
  r1 attached to the fix it describes; that branch was far behind `main`
  (`git rev-list --count origin/claude/merge-notice-reach-79e466..origin/main`
  = 94, 2026-09-11T23:13Z; it read 87 earlier in this session, `main` moved
  under it, and the first write of this line carried neither the command nor
  the minute) and its own `next:` line was stale (it said "make the two text
  edits", which its second commit had already made).

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
  before. (fixed. Correction, this session: r1's `:304`/`:316` are gx's copy of
  the file, not this repo's — here the two hits are `:416`/`:428`
  (`git grep -n "session id" HEAD -- .claude/commands/orchestrate.md`,
  2026-09-11). A reader following r1's numbers lands in the health pass.)
- r2: the spawn block told the orchestrator to write
  `"<your ListAgents name>"` while its gate stayed `ToolSearch("+SendMessage")`
  — and NOTHING in `orchestrate.md` calls `ListAgents` for the orchestrator's
  own row (`grep -n ListAgents .claude/commands/orchestrate.md`: 24, 40, 149,
  and the merge line itself; the first three are about the TARGET's row). So
  the fix traded an address `SendMessage` refuses for one the caller cannot
  obtain, and a literal reader would have to guess the string. (fixed — gate
  now calls `ListAgents`. Two claims in this line's first draft were wrong and
  are corrected by r5 and r7 below: `:40` is the OPTIONAL tools row, not a
  target's row; and one `ListAgents` call yields the NAME, never `SendMessage`,
  which is still found the way the Tools paragraph says.)
- r3: same block said the name form holds "here as at the NUDGE row
  below". NUDGE is `orchestrate.md:149`, the merge line `:412` — above, not
  below. A reader sent the wrong way to check the one cross-reference the
  argument rests on. (fixed)
- r4: (verifier) WORST of the round, and it lands on my own fix. The new gate
  still could not fire on the runtime that produced the issue. Its three
  disqualifiers were no `ListAgents`, no `SendMessage`, no name in the opening
  line; on gx all three are satisfied — the issue's transcript calls
  `ListAgents`, `ToolSearch("+SendMessage")` returns the tool, and the output
  opens `This session is gx-4b [79e466]`. So the line is emitted and the send
  refused exactly as #230 reports, with only the address string changed:
  defect 1 reworded, not fixed. The same paragraph called `ListAgents` and
  discarded the one half of its output that discriminates, then asserted
  "nothing readable here tells them apart" — contradicted by the transcript it
  cites. (fixed: the gate is the peer row, which is what #230 proposed. This
  branch's first ruling rejected it as unknowable because peer visibility
  belongs to the manager's unborn container; that reasoning holds for the
  manager and not for the fabric — no peer row in the ORCHESTRATOR's own
  container means this runtime routes nothing between sessions. The false
  negative it does admit, a first spawn with no manager up, costs one pass and
  is named in the text.)
- r5: (verifier) the quoted `ListAgents` opening line was not the measured one.
  The file quoted "… the name other sessions use to message it"; #230's
  transcript carries no such clause. The branch refused to claim a session
  title is an address because that was unmeasured, then rested the replacement
  on a quotation nobody can source — a written number in this repo's terms.
  (fixed: the sourced string is `SendMessage`'s own refusal, "Use ListAgents to
  see everyone you can message", which IS in the transcript; the invented
  clause is gone.)
- r6: (verifier) a SHIPS plan owes a check a CONSUMER runs
  (`.agents/docs/plans/README.md`); all four criteria were local, and the
  ship-scope stage reports without redding, so `ci: pass` did not catch it.
  (fixed: an acceptance criterion that reads a spawn prompt in gx after its
  sync — the runtime where the line must now be ABSENT.)
- r7: (verifier) `manage.md` handed the manager ONE cause for a refusal that
  `orchestrate.md`, in the same diff, calls two faults behind one string. A
  consumer not yet synced still emits the id form, so its manager gets the
  refusal for the address fault and is told the cause is the route — and the
  new "do not hunt a second way" removes the two probes that are the only
  reason #230 exists. Exit behaviour right, diagnosis wrong. (fixed: both
  faults named, and that you cannot tell them apart from inside.)
- r8: (verifier) the OPTIONAL row's remedy, "drop the last line of the spawn
  prompt", names the wrong line — four lines follow the merge line, so on a
  RESPAWN a literal reader drops the resume line and the successor restarts a
  plan on a branch already carrying work. Pre-existing, and the plan had
  declared this row out of scope as "correct as written". (fixed here, one
  phrase, plus the peer-row trigger; Out of scope says why it moved.)
- r9: (verifier) "Call `ListAgents` once" gave no discovery step, against the
  file's own rule that tool names carry an unstable prefix and are found with
  `ToolSearch`. With `ToolSearch` demoted four lines later, a literal reader
  whose bare call does not resolve drops the merge line on EVERY runtime —
  the second half of the PR218 r3 failure this line exists to avoid. (fixed:
  find both tools as the Tools paragraph says; `ListAgents` yields the address,
  `ToolSearch` still finds the tools.)
- r10: (verifier) acceptance criterion 1 named an output no run prints —
  `git grep -c` with no match prints nothing and exits 1, not `0`. It does
  discriminate, so not r1's class, but a scripted reader sees a non-zero exit
  and reads failure. (fixed: stated as `git grep -q` exiting 1.)
- r11: (verifier) the paragraph stated the tool-is-not-a-route fact twice and
  quoted `No agent named X is reachable` where the measured string carries a
  real id, against caveman's "state each fact once" and "error strings quoted
  exact". (fixed: said once; the inexact quote replaced by the refusal text
  that is exact, and the two-faults-one-string point kept as prose.)
- r12: (verifier) it could not call `ListAgents`,
  `SendMessage` or `ToolSearch` — a subagent has no MCP tools mounted, the
  limit PR218 r8 already recorded. Its claims about those tools are reasoned
  from #230's transcript, which it re-fetched. Recorded so the next reader
  knows which half of this review is re-runnable and which rests on the issue.
  (no change needed)
- r13: (verifier) cherry-pick fidelity — the command-file hunks of
  `5cd9a3a` and `1b71f02` are byte-identical to the originals, the differing
  patch-id being base drift; direction claim "above" correct; zero glossary-ban
  hits in added lines; no step 7 `verify` obligation, the diff touching no
  non-`*.md` path under the four guarded roots. (no change needed)

## Blockers

None.

## Where to look

- `docs/plans/merge-notice-reach.md` — scope, acceptance, traps.
- `.claude/commands/orchestrate.md`, `create_session` bullet and the NUDGE row.
- `.claude/commands/manage.md`, section 4 Finish.

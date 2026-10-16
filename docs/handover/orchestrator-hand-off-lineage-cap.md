---
workstream: orchestrator-hand-off-lineage-cap
status: review
branch: claude/orchestrator-hand-off-lineage-cap
pr: 506
plan: orchestrator-hand-off-lineage-cap
issue: none
session: https://claude.ai/code/session_01NAJQNsQCP5ob8fkWYjKsVg
agent: opus
updated: 2026-10-16
next: ci, verify, retire again, merge #506
---

## Goal

Settle `docs/research/orchestrator-hand-off-lineage-cap.md`: can §4 HAND-OFF
strand the fleet at the control plane's lineage cap; graduate the guard into
`.claude/commands/orchestrate.md`.

## Decisions

- Second context = this manager session's own `get_session` calls: own
  record carries `lineage` depth 1 limit 8 (parent = orchestrator, origin
  ios); parent record carries no `lineage`; all nine gx ids walked, linear
  chain, root has no `parent_session_id`, created_at matches the table.
- Guard threshold `depth + 1 < limit`: the successor must stay below the
  cap to spawn and arm; its managers may sit AT the cap, since no role
  command calls `create_session` or `send_later`.
- §0 check rides step 2 (after `authority`), so a capped session stops
  before step 3 takes the title; no step renumbered.
- Once-only push via run-scoped ledger key `capped=<depth>`.
- Heartbeat depth left as a stated unmeasured operator reading: creating a
  Routine is recurring spend, operator only.

- Human asked (this session) for a cheap long-lived heartbeat. First cut
  (§4 ENDS when a heartbeat exists, 72141be) reverted after review r10-r16;
  the design is plan `orchestrator-heartbeat-successor` in this PR, gated on
  a measured Routine-fired depth.

## Rejected

- END at the pass limit with the heartbeat as successor: loses the ledger,
  leads and the one-orchestrator rule (r10-r13).
- A long-lived keeper session: idle is free but every pass re-reads the
  session's history, so cost per pass grows; the scheduler is the durable
  piece, never a session.
- Push keyed on `pass=` = passes + 1: an out-of-band arm or a knob change skips that number and the push never fires (verifier r3).

## Review

- r1: (verifier) new selftest needle with backticks lacked `# shellcheck disable=SC2016`; `ci` red (fixed)
- r2: (verifier) needles stopped at `<`, so a `<=` mutation passed (fixed: full comparison on folded text; mutation `<=` now 0 matches, origin/main 0)
- r3: (verifier) once-only push keyed on `pass=` = passes + 1 skippable by an out-of-band arm or knob change (fixed: run-scoped ledger key `capped=<depth>`; lineage check runs first in step 1)
- r4: (verifier) hand-off interval range 66 to 68, table gives 69 (fixed)
- r5: (verifier) doc paragraph told who-found-what, narrated the incident, and its measured number named no date (fixed: command and date named, narration cut)
- r6: (verifier) deleted the request for a hand-off `context:` reading the gx chain does not supply (fixed: sentence restored)
- r7: (verifier) §0 lineage stop ran after step 3 took the title; no `get_session` uncovered (fixed: moved into step 2, `no get_session = proceed`)
- r8: (verifier) "today's rule" time-relative (fixed: text rewritten, `the rest of this step decides alone`)
- r9: (verifier) §0 stop report carries no heartbeat line (no change: a stop at the cap runs nothing after it; the push names the fix)
- r10: (verifier) END path: step 3 exits only on RUNNING, an orchestrator between passes reads IDLE, so hourly firings overlap a live one (fixed: END reverted; plan scopes an IDLE-with-updated_at rule)
- r11: (verifier) END discards the ledger: respawns restored at the limit, once-only pushes repeat hourly, KILL interrupt lost (fixed: END reverted; plan carries the ledger via fire_trigger text)
- r12: (verifier) leads to an ended session lost (fixed: END reverted; plan forwards to the fired session)
- r13: (verifier) any enabled Routine for the repo counted as the heartbeat (fixed: END reverted; plan requires an /orchestrate prompt and a non-FAILED last_run)
- r14: (verifier) a daily Routine leaves managers unsupervised up to a day (fixed: END reverted; plan fires the successor at once)
- r15: (verifier) orchestrated.md still said the orchestrator always hands off (no change: true again after the revert; plan scopes it)
- r16: (verifier) new needles pinned spelling only (fixed: END reverted with its needles; plan requires per-clause mutation)
- r17: (verifier) @new rebuild counts claimed managers as pending on a first pass (wontfix: predates this diff; named in the plan's scope via step 3)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` — §0 Start, §4 HAND-OFF.
- `.agents/docs/orchestrated.md` — "Start each run fresh", Heartbeat.

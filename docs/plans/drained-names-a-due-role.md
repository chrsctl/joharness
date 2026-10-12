---
plan: drained-names-a-due-role
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 428
scope: shared:joharness.sh, shared:.claude/commands/orchestrate.md, .agents/harness/selftest/dispatch.sh
---

## Goal

On 2026-10-12, dispatch printed `verdict : DRAINED — nothing free, nothing in
flight: exit, the heartbeat re-seeds` and, on the next line, `clerk DUE:
spawn ONE clerk`. orchestrate.md §4 says that verdict means "final report,
no next pass". The two lines contradict each other, and a literal reader
could exit without ever spawning the due role. When a curator or clerk
spawn line follows under that verdict, the verdict must say so.

## Scope

- `joharness.sh:cmd_dispatch`: compute whether a `curate DUE: spawn` or
  `clerk DUE: spawn` line will print before printing the plain DRAINED
  verdict. When one will, print instead `verdict   : DRAINED — nothing
  free, nothing in flight; a role is due: spawn it, then schedule the next
  pass`. The exact wording is the implementer's, but it must name the role
  spawn and must not contain `: exit`. Leave the other verdict lines and
  the scout gate (`scout_gate`) unchanged. The scout spawns only at the
  unqualified DRAINED.
- `.claude/commands/orchestrate.md` §4: the exit sentence names only the
  unqualified line and adds the new one to "`… in flight` = schedule" (or
  equivalent).
- `.agents/harness/selftest/dispatch.sh`: one case where a clerk or curate
  is due at DRAINED expects the new verdict and no `: exit` on the verdict
  line. The existing line-86 and line-96 cases keep passing. The new case
  must FAIL against `origin/main`'s `joharness.sh`; record that in
  `## Review`.

## Out of scope

- The clerk clock (#424). Use a fixture where the clerk is due by the current reader, or the curate cycle, so this plan does not wait on #424.
- Edge-work versus leftovers classification for a done surveyor branch (raised in the review, not filed).

## Acceptance

- `bash .agents/harness/selftest.sh dispatch` — green, including the new case.
- `./joharness.sh dispatch` on a fixture with a due role prints no line matching `DRAINED.*: exit` together with a `DUE: spawn` line.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `joharness.sh:cmd_dispatch`: the `verdict   : DRAINED — nothing free, nothing in flight` printf, and the `role_slots`, `curate_due` and `clerk_due` block after it.
- `.agents/harness/selftest/dispatch.sh`: the cases asserting the DRAINED verdict.
- `.claude/commands/orchestrate.md` §4, "`DRAINED — nothing free, nothing in flight: exit` or `PAUSED`".

## Traps

- A test for a fix must FAIL without it.
- `#424` edits the clerk readers in `joharness.sh` and may touch `cmd_dispatch`'s clerk gate: reconcile expected at step 7.
- `#425`, `#426` and `#427` also edit orchestrate.md.

---
plan: drained-names-a-due-role
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 428
scope: shared:joharness.sh, shared:.claude/commands/orchestrate.md, shared:.agents/harness/selftest/dispatch.sh
---

## Goal

On 2026-10-12, dispatch printed two contradictory lines:
- `verdict : DRAINED — nothing free, nothing in flight: exit, the heartbeat re-seeds`
- on the next line, `clerk DUE: spawn ONE clerk`.

orchestrate.md §4 reads that verdict as "final report, no next pass", so a literal reader could exit without spawning the due role. When a curator or clerk spawn line follows the plain DRAINED verdict, the verdict must say so.

## Scope

- **`joharness.sh:cmd_dispatch`.** Decide whether a `curate DUE: spawn` or `clerk DUE: spawn` line will print before printing the plain DRAINED verdict. When one will, print a variant instead:
  - Example: `verdict   : DRAINED — nothing free, nothing in flight; a role is due: spawn it, then schedule the next pass`.
  - The wording is the implementer's, but it must contain `a role is due` and must not contain `: exit`.
  - The other verdict lines are unchanged.
  - `scout_gate` is unchanged: the scout spawns only under the unqualified DRAINED.
- **`.claude/commands/orchestrate.md` §4.** The exit sentence names only the unqualified line. Add a separate clause for the new verdict: "`… a role is due` = spawn the role, schedule the next pass". It must not join "`… in flight` = schedule, no spawn".
- **`.agents/harness/selftest/dispatch.sh`.** Add one case with a curate due at DRAINED.
  - Use curate, not the clerk: this file's `dsp` helper runs with `DISPATCH_FETCH=0`, and its fixture has no `.claude/commands/clerk.md`, so a clerk reads `off` or `held`.
  - Expect `a role is due` on the verdict line, and no `nothing in flight: exit` line.
  - The existing DRAINED cases keep passing.
  - Prove the case fails without the fix:
    1. `git checkout origin/main -- joharness.sh`.
    2. Run `.agents/harness/selftest.sh` whole. It takes no topic argument.
    3. Record that the new case fails, in `## Review`.
    4. `git checkout HEAD -- joharness.sh`.

## Out of scope

- The clerk clock (#424).
- Classifying a done surveyor branch as edge work versus a leftover. This was raised in the review and not filed.

## Acceptance

- `.agents/harness/selftest.sh`: green, including the new case. It fails on `origin/main`'s `joharness.sh`, as recorded in `## Review`.
- `./joharness.sh ci`: `ci: pass`. Every consumer's `ci` runs the same selftest at its next sync.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `joharness.sh:cmd_dispatch`: the `verdict   : DRAINED — nothing free, nothing in flight` printf, then the `role_slots` / `curate_due` / `clerk_due` block after it.
- `.agents/harness/selftest/dispatch.sh`: the cases asserting `DRAINED — nothing free, nothing in flight: exit, the heartbeat re-seeds`, and the `dsp` helper.
- `.claude/commands/orchestrate.md` §4: "`DRAINED — nothing free, nothing in flight: exit` or `PAUSED`".

## Traps

- A test for a fix must FAIL without it. See the procedure in Scope.
- `clerk-cycle-reads-what-a-clerk-leaves` (#424) also edits `joharness.sh` near `cmd_dispatch`'s clerk gate. The other orchestrate.md plans (#425, #426, #427, #429) touch other sections. Reconcile expected at step 7.

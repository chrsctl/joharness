---
plan: orchestrator-human-ordered-extras
urgency: normal
agent: sonnet
effort: high
needs: role-session-standard-lines, clerk-cycle-reads-what-a-clerk-leaves
requirement: none
issue: 425
scope: shared:.claude/commands/orchestrate.md
---

## Goal

On 2026-10-12 the human answered a HUMAN issue mid-run and asked for it to be planned now. orchestrate.md has no lawful path for "the human orders an extra role session", so the orchestrator improvised three moves:

1. It messaged the finished clerk: "Please run one more /clerk pass on #251".
2. It spawned a second clerk whose prompt asserted its own authority: "The repository owner asked for this extra clerk pass…".
3. It left its pending wake stale. The wake still read "clerk already ran this run — at most one per run" and named only the first clerk.

Give the human's order one defined path, and close the three improvisations.

This plan reads two results:
- `role-session-standard-lines` (#427) defines "the role lines".
- `clerk-cycle-reads-what-a-clerk-leaves` (#424) makes IN FLIGHT the clerk's only exit and counts a clerk in flight whatever the clock reads. Without that, a lawful extra clerk exits at its own precondition.

## Scope

`.claude/commands/orchestrate.md` only:

- **§3 Spawn: add one bullet after the role table, "the human orders an extra role session".** The human's explicit order, typed in this session, allows ONE extra session of that role beyond "at most ONE of each per run".
  - **Prompt:** the command plus the lines that role's row gets ("the role lines" for clerk, curator and scout; "the standard lines" for the surveyor), with nothing added.
  - **Ledger:** the role's own key carries the mark, e.g. `clerked=<stamp>+human`. One mark per role key, so two roles' extras stay distinct. Add the form to §4's ledger format line.
  - **Report:** quotes the human's words. The prompt never does.
  - **Guard:** it never spawns while dispatch shows that role IN FLIGHT.
- **§4 Schedule: a spawn made outside a scheduled pass (in answer to the human) arms one new `send_later` at once, in §4's format.**
  - **A wake is pending** (`list_triggers` `include_completed` lists one for this session):
    - The new wake's `pass=` is one higher than the pending wake's `pass=`. Pass entry's superseded check then makes the stale wake do nothing, and nothing is cancelled.
    - Its ledger is the pending wake's stored ledger plus this spawn, never written from memory.
  - **No wake is pending** (the run already ended at DRAINED or PAUSED): treat it as a first start, with `pass=1` and a ledger holding only this spawn.
  - **No `list_triggers`:** say so to the human and arm nothing. Dispatch reads the spawn from git once it pushes.
- **Never: add one line.** "Message a child session asking it to do more work. `send_message` to a child carries the health table's nudge text and nothing else."

## Out of scope

- clerk.md and `joharness.sh`. The clerk's preconditions and the in-flight count are #424's.
- Posting the human's answer on the issue (#426).
- Defining the role lines (#427).

## Acceptance

- `grep -n "+human" .claude/commands/orchestrate.md`: the §3 bullet and the §4 ledger format line.
- `grep -n "nudge text and nothing else" .claude/commands/orchestrate.md`: the new Never line.
- `./joharness.sh ci`: `ci: pass`, glossary lint included. Consumers run the same lint on this file at their next sync.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `.claude/commands/orchestrate.md` §3: "Role sessions, at most ONE of each per run", and the role table.
- `.claude/commands/orchestrate.md` "Pass entry": the **Superseded** bullet. The re-arm relies on it.
- `.claude/commands/orchestrate.md` §4: the `send_later` format block and the ledger rules.
- `.claude/commands/orchestrate.md` "Report, every pass": the "if the human orders it" carve-out for branch plans. Match its shape.

## Traps

- The prompt routes and the repository authorises. The extra-spawn bullet adds no line to the prompt.
- The ledger comes from a wake message, never from memory, and that includes the out-of-pass re-arm.
- `relayed-answer-is-quoted`, `role-session-standard-lines`, `drained-names-a-due-role` and `fresh-orchestrator-per-run` also edit orchestrate.md. Reconcile expected at step 7.

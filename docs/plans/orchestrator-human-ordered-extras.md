---
plan: orchestrator-human-ordered-extras
urgency: normal
agent: sonnet
effort: high
needs: role-session-standard-lines
requirement: none
issue: 425
scope: shared:.claude/commands/orchestrate.md, shared:.claude/commands/clerk.md
---

## Goal

On 2026-10-12 the human answered a HUMAN issue mid-run and asked for it to be planned now. orchestrate.md has no lawful path for "the human orders an extra role session", so the orchestrator improvised three moves:

1. It messaged the finished clerk: "Please run one more /clerk pass on #251".
2. It spawned a second clerk whose prompt asserted its own authority: "The repository owner asked for this extra clerk pass…".
3. It left its pending wake stale. The wake still read "clerk already ran this run — at most one per run" and named only the first clerk.

Give the human's order one defined path, and close the three improvisations.

## Scope

- **`.claude/commands/orchestrate.md` §3 Spawn.** Add one bullet after the role table: "the human orders an extra role session". The human's explicit order, typed in this session, allows ONE extra session of that role beyond "at most ONE of each per run".
  - **Prompt:** the command plus the role-session lines that `role-session-standard-lines` defines, with nothing added.
  - **Ledger:** the role's own key carries the mark, e.g. `clerked=<stamp>+human`. One mark per role key, so two roles' extras stay distinct. Add the form to §4's ledger format line.
  - **Report:** quotes the human's words. The prompt never does.
  - It still never spawns while that role is IN FLIGHT per dispatch.
- **`.claude/commands/orchestrate.md` §4 Schedule.** A spawn made outside a scheduled pass (in answer to the human) arms one new `send_later` at once, in §4's format.
  - Its `pass=` is one higher than the pending wake's `pass=`. Pass entry's superseded check then makes the stale wake do nothing, and nothing is cancelled.
  - Its ledger is the pending wake's stored ledger, read with `list_triggers` `include_completed`, plus this spawn. It is never written from memory.
  - No `list_triggers`: say so to the human and arm nothing. The pending wake runs with its stale ledger, and dispatch reads the spawn from git once it pushes.
- **`.claude/commands/orchestrate.md` Never.** Add one line: "message a child session asking it to do more work — `send_message` to a child carries the health table's nudge text and nothing else."
- **`.claude/commands/clerk.md` §0.2.** Change "Not due = exit" so that IN FLIGHT stays the clerk's only exit. Cadence is dispatch's gate for SPAWNING a clerk. The orchestrator's table and this plan's human-order bullet enforce the count. Without this change, a human-ordered extra clerk exits at its own precondition once `clerk-cycle-reads-what-a-clerk-leaves` (#424) makes the clock read correctly.

## Out of scope

- The clerk-clock reader (#424).
- Posting the human's answer on the issue (#426).
- Defining the role-session lines (#427). This plan reads that result, hence `needs`.
- Any `joharness.sh` change.

## Acceptance

- `grep -n "+human" .claude/commands/orchestrate.md`: the §3 bullet and the §4 ledger format line.
- `grep -n "nudge text and nothing else" .claude/commands/orchestrate.md`: the new Never line.
- `grep -n "Not due = exit" .claude/commands/clerk.md`: no hit.
- `./joharness.sh ci`: `ci: pass`, glossary lint included. Consumers run the same lint on these files at their next sync.
- `./joharness.sh verify`: 0 failed.

## Where to look

- `.claude/commands/orchestrate.md` §3, "Role sessions, at most ONE of each per run".
- `.claude/commands/orchestrate.md` "Pass entry", the **Superseded** bullet. The re-arm leans on it.
- `.claude/commands/orchestrate.md` §4, the `send_later` format block and the ledger rules.
- `.claude/commands/orchestrate.md` "Report, every pass", the "if the human orders it" carve-out for branch plans. Match its shape.
- `.claude/commands/clerk.md` §0 Preconditions.

## Traps

- The prompt routes and the repository authorises. The extra-spawn bullet adds no line to the prompt.
- The ledger comes from a wake message, never from memory. That includes the out-of-pass re-arm.
- orchestrate.md and clerk.md are protocol text, not core paths. `joharness.conf`, `.claude/settings.json` and `.github` are core paths.
- `relayed-answer-is-quoted`, `drained-names-a-due-role` and `fresh-orchestrator-per-run` also edit orchestrate.md. `clerk-cycle-reads-what-a-clerk-leaves` also edits clerk.md §0. Reconcile expected at step 7.

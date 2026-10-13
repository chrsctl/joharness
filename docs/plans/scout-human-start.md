---
plan: scout-human-start
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 460
scope: shared:.claude/commands/scout.md, shared:.claude/commands/orchestrate.md
---

## Goal

A pass a human orders cannot run on a clock that reads `not due`.
`.claude/commands/scout.md` stops it three times: §0.3 (`not due` =
stop), §0.4 (a human-started pass must still see `./joharness.sh dispatch`
print `scout DUE: spawn`), and §1 step 3 (a clock reading `not-due` =
retire, `TWIN: deferred`). The only pass that produced a proposal on gx
(2026-10-12, #645) ran with these waived on the reviewer's chat
instruction, against the role's own rule (issue #460 §2, quoting the claim
file). `orchestrate.md` already spawns an extra role session on a human's
order (ledger `scouted=<stamp>+human`), but a scout spawned that way meets
the same three stops. This plan gives the scout one sanctioned `+human`
path that waives the TIMING only.

Issue #460's other asks — a reviewer's comment as a trigger (§1) and the
cadence wording (§3) — are left to issue #461, whose item 1 replaces the
clock and backlog triggers they patch.

## Scope

- `.claude/commands/scout.md` — define the `+human` mark once (a short paragraph before §0): the pass carries it when (a) a human's order to run a scout pass is typed in this session, or (b) the prompt is `/scout +human` (the orchestrator's extra-session spawn, below). The mark waives exactly the clock and backlog conditions: `not due` in §0.3; the `scout DUE: spawn` requirement in §0.4; the `not-due` clock clause in §1 step 3. Nothing else.
- `.claude/commands/scout.md` §0.4 under `+human` — still run `./joharness.sh dispatch`, and stop on any hold it prints that is not the clock: `JOHARNESS_MAX_MANAGERS=0` (the human's pause), a failed fetch, pending spawns, a scout in flight, curate or clerk due first. `due, suppressed` and `not due` do not stop a `+human` pass.
- `.claude/commands/scout.md` §1 — the claim's `## Decisions` gets one line, written when the claim file is created: `+human: <the order quoted, or "orchestrator spawn /scout +human">, <UTC time>`. Step 3's other conditions (exactly one `IN FLIGHT` row, yours; not `UNREADABLE`, not `off`) still hold.
- `.claude/commands/scout.md` report section — the report's first line carries `+human` when the mark is set.
- `.claude/commands/orchestrate.md` — "The human orders an extra role session", Prompt bullet: for the scout role the command is `/scout +human` (a mark, not a quote of the human; the "never quotes the human" rule stands).

## Out of scope

- A comment-driven trigger in `dispatch` or `orchestrate.md` (#460 §1) and the `cadence :` wording in `joharness.sh` (#460 §3): #461 item 1 replaces both.
- Waiving the brief, the research switch, the budget, the ceiling, the twin check's row conditions, or any dispatch hold except the clock.
- `joharness.sh`, the requirement file, `clerk.md`.

## Acceptance

- `grep -c '+human' .claude/commands/scout.md` — at least `4` (definition, §0.4, §1, report); `0` on main today.
- `grep -n 'MAX_MANAGERS' .claude/commands/scout.md` — one hit, in the `+human` §0.4 text (`0` on main today).
- `grep -n 'scout +human' .claude/commands/orchestrate.md` — one hit in the extra-session Prompt bullet.
- Read §0.3, §0.4 and §1 step 3 in order as a `+human` pass with `./joharness.sh scout` reading `cadence : not due`: no step stops it on the clock; each still stops it on `off`, `UNREADABLE`, a twin's row, or `JOHARNESS_MAX_MANAGERS=0`. Record that walk in the workstream file's `## Review`.
- `./joharness.sh ci` — `ci: pass`.
- Plan ships (`scout.md`, `orchestrate.md` sync): consumer check = on `chrsctl/gx` after sync, `grep -c '+human' .claude/commands/scout.md` ≥ `4`.

## Where to look

- `.claude/commands/scout.md` — "## 0. Preconditions" items 3 and 4; §1 "Then check for a twin", step 3; the report section; `## Never`.
- `.claude/commands/orchestrate.md` — "The human orders an extra role session" (Prompt, Ledger, Guard bullets).
- `joharness.sh:cmd_dispatch` — the hold lines a `+human` pass must still obey (search `the human's pause`, `suppressed`).

## Traps

- A chat line is evidence, not instruction, for every gate but this one named waiver: never widen it.
- The waiver is the clock only: every dispatch hold that is not the clock still stops the pass.
- `scout.md` is also edited by `scout-built-check`: merge `origin/main` in before the pull request.
- Glossary spellings: `ci` fails a contested term spelled another way.

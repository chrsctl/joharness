---
plan: retired-branch-holds-slot-past-refused-merge
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: .claude/commands/orchestrate.md, joharness.sh, .agents/harness/selftest/dispatch.sh
---

## Goal

A consumer orchestrator (chrsctl/gx, 2026-10-14 to 15) carried a retired
branch whose manager ran step 7, had its merge refused by its own permission
policy, and went IDLE asking a human to merge (PR gx#714, open and ready). No
health-table row covers that state, so the slot stayed counted for 29 passes
(1 of 4, 25% of the fleet) while 32-37 items waited. Nothing the orchestrator
sends changes it: a nudge meets the same refusal, a respawn inherits the same
policy. And `dispatch` says "a pull request is expected; this reader cannot
see one" when the truth was "open, waiting on a human merge". Give the state
a row, release its slot the way a `blocked` workstream holds none, and make
the dispatch text say what it actually knows. The answer comes from the
retired research node `retired-branch-holds-slot-past-refused-merge`; recover
it with
`c=$(git log -1 --format=%H --diff-filter=D -- docs/research/retired-branch-holds-slot-past-refused-merge.md)`
then `git show $c^:docs/research/retired-branch-holds-slot-past-refused-merge.md`.

## Scope

- `.claude/commands/orchestrate.md`, health table: a row ABOVE the
  IDLE/PENDING `branch unmerged` nudge rows and beside
  `RUNNING | any | \`retired, no claim file\``:
  `IDLE | any | \`retired, no claim file\`, last turn asks a human to merge or
  grant merge permission (\`status_detail\` / needs-action)` =
  HELD BY HUMAN: never nudge, never respawn. `PushNotification` once carrying
  stem, branch, PR link, the session's ask verbatim; ledger
  `held-human=<pr>`; report only after. The row frees its slot.
  Drop the entry when the branch merges (existing `done` row).
- Same file, ledger format line: add `[held-human=<pr>]`.
- Same file, §3 Spawn: a `held-human=` entry holds no slot — spawn up to
  `slots` plus the number of such entries (as scout and conduct hold none).
- `joharness.sh` dispatch, the `retired, no claim file` edge row: replace
  "this reader cannot see one" with wording true for every case, in
  substance: "this reader does not read pull request state — the health pass
  does", keeping the rest of the row. `.agents/harness/selftest/dispatch.sh`
  asserts the old string: update it to the new one.

## Out of scope

- `dispatch` reading GitHub pull request state, or changing its slot count.
  It reads git only; the slot release lives in the orchestrator's ledger.
- Merging the pull request for the manager, or any permission change
  (`.claude/settings.json` is a core path).
- The `gone` edge row and the RUNNING `merging; nothing` row: unchanged.
- Any other page, rule line in `AGENTS.md`, or the glossary.

## Acceptance

- `grep -c 'held-human' .claude/commands/orchestrate.md` — 3 or more (row,
  ledger line, §3).
- `grep -c 'cannot see one' joharness.sh` — 0.
- `bash .agents/harness/selftest/dispatch.sh` — passes; and FAILS against the
  old `joharness.sh` (the assertion moved with the string).
- `./joharness.sh ci` — `ci: pass`. Both files ship to every consumer.
- `./joharness.sh verify` — `0 failed` (diff touches `joharness.sh`).

## Where to look

- `.claude/commands/orchestrate.md:health` — the table; `retired, no claim
  file` and the IDLE/PENDING rows.
- `.claude/commands/orchestrate.md:ledger` — the ledger format line.
- `.claude/commands/orchestrate.md:Spawn` — §3, who holds a slot.
- `joharness.sh:dispatch` — the `edge_rows` line carrying
  `retired, no claim file`.
- `.agents/harness/selftest/dispatch.sh` — the assertion on that row.

## Traps

- Row order matters: the first matching row wins; the new row must sit before
  the IDLE/PENDING nudge rows or a nudge-then-RESPAWN fires on it.
- `.claude/settings.json` and `.github` are core paths
  (`./joharness.sh protocol-paths`).
- NEVER skip, disable or quarantine a test to get green; the selftest string
  moves, it is not deleted.
- Contested terms have one spelling (`.agents/docs/glossary.md`); `ci` fails
  on the others.

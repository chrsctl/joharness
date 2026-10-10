---
workstream: new-entry-merged-between-passes
status: in-progress
branch: claude/new-entry-merged-between-passes
pr: none
plan: new-entry-merged-between-passes
issue: none
session: https://claude.ai/code/session_01MQpQFb9hmdy2KySGiVC4mD
agent: opus
updated: 2026-10-10
next: Spawn verifier on the diff, record findings in Review
---

## Goal

A manager that claims and merges between two health passes leaves its
ledger entry `new`; give that case one correct route through the health
rows instead of false "never claimed" / "gone before claim" reports.

## Decisions

- Test keys on the SESSION, not the item: a claim file on `origin/main`
  history whose `session:` is the session the title lookup resolved and
  whose `plan:` (surveyor: `workstream:`) is the stem. Session id comes
  from the control plane; a file carrying it reaches main only by merge.
  No ledger timestamp needed: session ids are unique per spawn.
- `--full-history` required: without it `git log -- docs/handover` prunes
  the side branch (file added and retired there, TREESAME at the merge)
  and printed nothing for #386's claim `ac87c5f` (measured 2026-10-10,
  `git log origin/main --diff-filter=A -S'session_012J8LutqGHqhZDE49agfS81' -- docs/handover`
  empty; with `--full-history` prints `ac87c5f`).
- Row sits FIRST in the decision table: every row keying on a `new` entry
  (crash, BLOCKED BEFORE CLAIM, gone before claim, UNCLAIMED, STILLBORN)
  then reads after it. It writes the claim commit as the head, so the
  `done` row's head condition stays as it is (out of scope to change).
- Row-by-row reading (acceptance):
  - plan merged, IDLE: MERGED BETWEEN PASSES -> head written -> `done`.
  - plan merged, RUNNING: same (stall rows need a push age a `new` entry
    lacks, and the new row is read first anyway) -> `done`.
  - plan merged, RUNNING+BLOCKED: new row before BLOCKED BEFORE CLAIM ->
    `done`; no interrupt, no report.
  - plan merged, FAILED: new row before the crash rows -> `done`; no
    archive, no respawn of a merged item.
  - plan merged, ARCHIVED: lookup takes the newest archived session under
    the title -> new row -> `done` (not `gone before claim`).
  - requirement planned and merged: claim file names the requirement in
    `plan:` (`.agents/docs/product/README.md`); keyed on session, so the
    requirement file still on main does not matter -> `done`.
  - surveyor `rescope-<key>@new`: title `surveyor: <key>`, claim file
    `workstream: rescope-<key>` -> `done`.
  - item deleted by `/curate`, manager prompt-held: no merged file carries
    its session id -> new row prints nothing -> BLOCKED BEFORE CLAIM first
    look, then confirm: item gone -> REPORT, touch nothing. Correct: it
    never claimed.
  - no session found at all: no id, row cannot match -> `gone before
    claim` as before.

## Rejected

- Item file gone from `origin/main` (r13-r16 of `blocked-before-claim-row`):
  crash rows precede it, no item path for a surveyor, curate fakes it,
  requirement survives its planning merge.
- Merge message as the test: optional, no transport = no message.
- Ledger timestamp for `@new`: not needed once the test keys on session id.

## Review

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` `## 2. Health pass` — the `new` rows.

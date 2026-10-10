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
next: Second verifier pass on r1-r9 fixes
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
- Guard: dispatch lists the stem nowhere (in flight, spawn, held). The
  session-id match alone was forgeable and stale-able (r1, r2); a merge
  that really finished the item takes it off the queue — plan retired,
  requirement planned, rescope key resolved.
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

- r1: (verifier) archived fallback can resolve an earlier run's session S1 whose claim for a re-queued stem is on main, marking a live entry done. (fixed — row also requires dispatch to list the stem nowhere; a re-queued item is listed, so the row fails)
- r2: (verifier) any session can merge a file naming the victim's session id and `plan: <stem>`, dropping a live entry. (fixed in part — the dispatch clause: a forgery must also merge the item off the queue, and then nothing can be spawned twice; wontfix the residual one-slot-over-cap, no git reading is unforgeable by a session that can merge)
- r3: (verifier) orchestrated.md row required "no branch in flight", command row did not; orchestrated.md done row's "plan file gone" never holds for requirement or surveyor. (fixed — both rows carry the same dispatch clause; done row says item off the queue)
- r4: (verifier) REPORT needs `<branch>`, the rewritten entry carries none. (fixed — taken from the claim file's `branch:` line)
- r5: (verifier) "any of the five exists" stale after SIX. (fixed)
- r6: (verifier) orchestrated.md worked readings said "the first row" meaning the RUNNING under-stall row. (fixed — named)
- r7: (verifier) orchestrated.md anchor "or it ran and stopped without claiming" no longer in orchestrate.md. (fixed — sentence reordered, phrase restored)
- r8: (verifier) BLOCKED BEFORE CLAIM confirm parenthetical gave merged-between-passes as the reason. (fixed — reason now curated or another branch's merge; row behaviour kept)
- r9: (verifier) several commits may print; which is the head unspecified. (fixed — the first printed)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` `## 2. Health pass` — the `new` rows.

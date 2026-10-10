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
next: Retire plan and workstream file, open PR, merge
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
- Identity: `sid=` on the `@new` entry, written from `create_session`'s
  return, by every spawn incl. STILLBORN / BLOCKED BEFORE CLAIM re-spawns.
  NOT rebuilt from titles in step 0.2: a title row may be an earlier run's
  session (r14). Not a timestamp; ties
  the claim to THIS spawn, so an earlier run's claim under a reused stem
  or key cannot match (r1, r10). Control-plane id == URL suffix: read
  2026-10-10, `get_session` on this session returned
  `session_01MQpQFb9hmdy2KySGiVC4mD`, the string in this file's `session:`.
- Guard: item off `origin/main` (plan/research file gone; requirement:
  a plan names it in `requirement:`). Replaces "dispatch lists it
  nowhere", which drain's `head -1` on requirements made false (r10).
  Surveyor has no item and holds no slot; `rescoped=` bars a second.
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
  - plan merged, ARCHIVED: `sid=` names the session whatever its status
    -> new row -> `done` (not `gone before claim`).
  - requirement planned and merged: claim file names the requirement in
    `plan:` (`.agents/docs/product/README.md`); keyed on session, so the
    requirement file still on main does not matter -> `done`.
  - surveyor `rescope-<key>@new sid=`: claim file
    `workstream: rescope-<key>`, no item clause -> `done`.
  - item deleted by `/curate`, manager prompt-held: no merged file carries
    its session id -> new row prints nothing -> BLOCKED BEFORE CLAIM first
    look, then confirm: item gone -> REPORT, touch nothing. Correct: it
    never claimed.
  - entry with no `sid=` (rebuilt from titles, pre-change ledger): row
    cannot match -> rows below decide, as before this row existed.

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
- r10: (verifier, pass 2) "dispatch lists the stem nowhere" is true for every requirement but the first unplanned one (drain_requirement `head -1`), so a stale or forged claim drops a live planner. (fixed — guard is the item off origin/main: a requirement needs a plan naming it in `requirement:`)
- r11: (verifier, pass 2) surveyor: an earlier run's archived surveyor under the same key resolves through the archived fallback and its merged claim matches. (fixed — `sid=` from create_session ties the entry to this spawn; title-lookup fallback removed)
- r12: (verifier, pass 2) `branch:` from repo text flows unchecked into `upstream` and a reporter prompt. (fixed — used only when it matches a plain ref charset and is merged into origin/main; else report without upstream)
- r13: (verifier, pass 2) control-plane id vs `session:` URL suffix unverified (`cse_` form exists). (fixed — measured equal: get_session id `session_01MQpQFb9hmdy2KySGiVC4mD` = this file's `session:` suffix, 2026-10-10)
- r14: (verifier, pass 3) step 0.2 rebuilt `sid=` from a title row, which can be an earlier run's IDLE merged session — r11 back through the rebuild. (fixed — rebuilt entries carry no `sid=`; loss line says so)
- r15: (verifier, pass 3) STILLBORN, BLOCKED BEFORE CLAIM and `new`-entry respawns did not replace `sid=`, so the successor's merge never matched. (fixed — each names the NEW session's `sid=`; the row says every fresh `@new` writes its own)
- r16: (verifier, pass 3) `sid=` loss line said nothing is spawned; crash rows can respawn. (fixed — says the rows below decide as before)
- r17: (verifier, pass 3) orchestrated.md requirement clause omitted "its file gone" (exits 3-4). (fixed — both doc rows)
- r18: (verifier, pass 3) `branch:` charset allowed a leading `-` read by `git fetch` as an option. (fixed — first char alnum or `_`)
- r9: (verifier) several commits may print; which is the head unspecified. (fixed — the first printed)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` `## 2. Health pass` — the `new` rows.

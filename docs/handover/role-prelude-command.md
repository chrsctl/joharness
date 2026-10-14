---
workstream: role-prelude-command
status: in-progress
branch: manage/role-prelude-command
pr: none
plan: role-prelude-command
issue: none
session: https://claude.ai/code/session_014WnbFzA7gTeyhacD1ne3ez
agent: opus
updated: 2026-10-14
next: ci + verify green, then finish: retire, PR, merge
---

## Goal

Replace the role commands' hand-written prelude (authority, fetch, report,
branch, claim, twin check, retire) with `./joharness.sh role <name>` printing
`GO` or `STOP: <reason>`; the commands keep only judgement.

## Decisions

- The text wins over the plan's step list (plan Traps). scout.md §0.3 reads
  no brief as `off`, a plain exit: no `NO BRIEF` claim-and-retire exists in
  the text, so `role scout` stops on `off` and claims nothing; the selftest
  case asserts that instead.
- curate.md names no in-flight check and no resume; `role curate` stops only
  on "no PROPOSE findings" (curate.md §0.2), plus `UNREADABLE`/`IN FLIGHT`
  should cmd_curate ever print one. Resume = a claim file of the role's own
  on HEAD, so it covers curate and scout; clerk and conduct write none.
- clerk's plain exits: IN FLIGHT and UNREADABLE (clerk.md §0.2: the only
  exit on a clean read; `off`/`not due` carry on).
- Every role's branch takes `-b`, `-c` on a name collision, not only the
  clerk's: scout.md names a claim FILE, not a branch, and a second same-day
  scout would otherwise hit non-fast-forward.
- Output: the reports print as they always did; the LAST line is `GO
  <branch>` (rc 0) or `STOP: <reason>` (rc 1). `--retire` prints `GO
  <branch> (retired)`.

## Rejected

- None yet.

## Review

- r1: (verifier) resume trusted a claim committed locally whose push failed: a re-run read `GO (resumed)` with nothing on origin (fixed: resume needs origin's copy of the branch to carry the claim; selftest "an unpushed claim is not a resume")
- r2: (verifier) a refused retire inside the scout twin check was hidden under `STOP: TWIN` as the last line (fixed: last line says the retire FAILED; selftest with a pre-receive hook)
- r3: (verifier) resume and `--retire` could fire on the base branch itself (fixed: both refuse the base branch)
- r4: (verifier) claim and retire commits took the whole index; `git rm` refused a locally edited claim (fixed: commit only the claim path; `rm -f`)
- r5: (verifier) prose `timeout 300` shorter than the command's own unshallow 300 s plus fetches (fixed: 600 s)
- r6: (verifier) orchestrated.md "11 lines in 8 files" not reproducible at the merge base (fixed: recounted at 6edf9b2 with the command: 15 in 8, fetch --prune 6 in 5; dropped the gx count this checkout cannot see)
- r7: (verifier) research noop-curate-stays-due anchors on curate.md §0 step 2, now in role_start_stop (no change: another item; sent as a lead after merge)
- r8: (verifier) scout resume lost "run ./joharness.sh scout for the conf lines" (fixed)
- r9: (verifier) seven mutations left the topic green: clerk GO tiebreak, start-path IN FLIGHT, curate GO, conduct twin Clock, origin-only name, twin fetch-fail retire, start fetch (fixed: cases added for the first five plus r1/r2; each mutation now fails the topic, measured 2026-10-14 with a scratch copy; the start fetch and the fetch-fail retire stay untested — no fixture fails a fetch without breaking the report reads)

## Blockers

None.

## Where to look

- `docs/plans/role-prelude-command.md` — the plan.

---
workstream: sampling-conduct-reviewer
status: in-progress
branch: sampling-conduct-reviewer
pr: none
plan: sampling-conduct-reviewer
issue: 251
session: https://claude.ai/code/session_01Qn8AF7S1z5UosETCFQcJpb
agent: opus
updated: 2026-10-12
next: ci, full selftest, retire, PR (Refs #251? check), merge on green checks
---

## Goal

Issue #251: add a sampling conduct reviewer — a periodic sonnet session that
reads a deterministic sample of retired managers' artifacts and records C1
(criterion asserts the refused behaviour) per branch in `docs/conduct-log.md`,
plus `./joharness.sh conduct` report with tally so the owner can judge the
spend.

## Decisions

- Ledger columns `date | stem | C1 | note`: plan Scope lists a `C2` column
  but also says only ONE question is asked; an always-empty column would
  skew the tally. A later plan adding the worker-ownership question adds C2.
  `conduct_rows` finds question columns by header name (`C<n>`), so that
  plan adds a column and the tally follows.
- Clock anchor = landing time of the newest base commit touching the ledger
  (merge above it, as `cycle_landed_ts`), read with its own rc check: the
  generic `cycle_age_h` reads a git error as "never", which is due — fail
  open. The ledger this PR adds starts the clock at its merge.
- Not the clerk's cycle reader: `cycle_landed_sha clerk` globs
  `docs/handover/clerk-*`, a file the clerk no longer writes (an urgent plan
  on another branch fixes that). In flight read straight from
  `for-each-ref --no-merged refs/remotes/origin/conduct-*`, tip push age
  past ceil(hours/7) = closed by a human, dropped.
- State `empty` (due, no unsampled candidate): dispatch spawns none — a
  reviewer with nothing to read is spend for nothing.
- `curate_due=2` (nothing needs judgement, no curator spawned) does not
  suppress, as the scout line reads `curate_due -ne 1`.
- Plan said the seeded heredoc lives in the bootstrap selftest; it lives in
  `.agents/scripts/bootstrap-consumer.sh` — edited there (one more file than
  `scope:` names, same intent).
- `.claude/commands/orchestrate.md` edited beyond `scope:` (verifier r4):
  without a row the orchestrator has no instruction for `conduct DUE`.
- Local `./joharness.sh verify` cannot pass here: Docker Hub answers 429 to
  this sandbox (`docker pull alpine:3`, 2026-10-12). GitHub's verify run on
  the head stands in (Loop step 7).
- Dispatch spawn-line cases live in `selftest/scout.sh`, not `dispatch.sh`:
  they need the conduct fixture (retired stems, ledger, conduct-* branches)
  that topic builds; a second fixture in `dispatch.sh` is a copy for nothing.

## Rejected

None yet.

## Review

- r1: (verifier) ledger clock re-dated by any manager merge-in of main (`log --full-history` picked the merge-in commit) — cycle may never come due (fixed: `log -1 --first-parent --format=%ct`, the landing itself; selftest merge-in case, fails with the old reader)
- r2: (verifier) role text pushed a commit-less branch before the twin check; it sits at main's tip, `--no-merged` hides it, every reviewer would defer (fixed: conduct.md commits the ledger rows first, pushes, then twin-checks)
- r3: (verifier) in flight matched `refs/remotes/origin/conduct-*` only; a `claude/conduct-*` branch was invisible (fixed: last path segment `conduct-*`; selftest prefixed-branch cases)
- r4: (verifier) orchestrate.md had no row acting on `conduct DUE` (fixed: role-session row, `conducted=<stamp>` ledger key, slot sentence)
- r5: (verifier) 14 new cases passed on the pre-change tree, determinism case compared two empty strings (fixed: refutes anchored on a line only conduct prints, sample must be non-empty; fixture checks are fail-only guards. scratch scout-only runner 2026-10-12: pre-change joharness.sh 99 passed, 50 failed = every new case; old scout.sh alone 99 passed, 0 failed)
- r6: (verifier) suppression tested for clerk due only (fixed: clerk in flight, curate in flight cases; mutation dropping `n_clerk` or `n_curate_inflight` each reds one case)
- r7: (verifier) janitor and findings sessions offered for sampling, real item `scout-command` excluded by `scout-` (fixed: candidate must name a `plan:` in its last workstream file; prefix narrowed to `scout-[0-9]`; selftest cases)
- r8: (verifier) role silent on a missing ledger (consumer first run) (fixed: conduct.md gives the exact header to create)
- r9: (verifier) landing read could take the next merge when the sha was itself the merge (fixed: same change as r1)
- r10: (verifier) runs = distinct ledger dates, two runs one day count once (wontfix: the clock spaces runs 168h by default; the output names the definition)
- r11: mutation re-run 2026-10-12, scratch scout-only runner: unmutated 149 passed, 0 failed; no `--first-parent` 1 failed, no prefix strip 4, no plan filter 5, no `n_clerk` 1, no `n_curate_inflight` 1, no closed-branch drop 2 (no change)

## Blockers

None.

## Where to look

- `joharness.sh:scout_due` — clock to copy.

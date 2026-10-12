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
- Candidate rule (research step after r7/r14 churn). Requirements: (a) plan:
  exclude periodic roles (scout-, curate-, clerk-); (b) r7: janitor and
  findings sessions buy only NO EVIDENCE; (c) r14: issue-driven manager
  items with `plan: none` must be sampled, conduct.md falls back for them;
  (d) r13: real items named `clerk-role`, `scout-command` must be sampled.
  The conflict was (b) solved by plan filter vs (c). Every role session's
  stem carries its UTC date; no manager item's does. Date shape satisfies
  all four. Measured 2026-10-12: 295 stems offered on this repo.
- Suppression narrowed to "a curate or clerk spawns this pass or is in
  flight": the plan says "due", but a due one held for a slot spawns
  nothing, and the plan's own reason (sampling competes with nothing) wins.
- Drop window floor 24h over the plan's HOURS/7 (r19): the default 168h
  gives 24h either way.
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
- r12: (verifier r2) conduct.md commit-order command died (`bad revision '^1'`) on a branch that reconciled after its retire, e.g. retire-survives-lost-github (fixed: walk `claim^..retire` first-parent; ran on that stem)
- r13: (verifier r2) `curate-|clerk-` prefix dropped real items (clerk-role), and no test failed without it (fixed: ONE rule, below r15)
- r14: (verifier r2) r7's plan filter excluded 103 real manager items (`plan: none` issue work) and made conduct.md's plan-less fallback dead — r7 fix undoing the plan's candidate rule (fixed: research step, see Decisions "candidate rule"; filter removed)
- r15: (verifier r2) churn resolution: role sessions all carry `-YYYY-MM-DD` in the stem, manager items never — the date shape is the single exclusion; selftest gives each role fixture a plan so the shape alone excludes it, plus clerk-role and a plan-less item that must be sampled (fixed)
- r16: (verifier r2) a clerk or curate held for a slot suppressed the reviewer indefinitely, though it needs no slot (fixed: suppress only when one spawns this pass or is in flight; case with JOHARNESS_MAX_MANAGERS=0. Deviates from the plan's literal "due" — recorded in Decisions)
- r17: (verifier r2) twin check dropped "clock still reads due": a reviewer could go on after another's rows landed (fixed: conduct.md requires `Clock:` due)
- r18: (verifier r2) two same-day reviewers share `conduct-<date>`; a rejected push had no step (fixed: `conduct-<date>-<HHMM>`, rejected push = stop)
- r19: (verifier r2) HOURS/7 drop gave a 1h window at HOURS=6, a reviewer waiting on checks read gone (fixed: floor 24h; 2h-old case at HOURS=6)
- r20: (verifier r2) no sha1 tool still read due: spawn, exit, respawn each pass (fixed: UNREADABLE; stub-PATH case)
- r21: mutation re-run 2026-10-12, scout-only runner: unmutated 155/0; no date rule 8 failed, held-suppresses 1, no floor 1, no sha check 2, no first-parent 1, no prefix strip 4, no n_clerk 1, no n_curate_inflight 1, no drop 2; pre-change joharness.sh 99 passed 56 failed (every new case) (no change)
- r11: mutation re-run 2026-10-12, scratch scout-only runner: unmutated 149 passed, 0 failed; no `--first-parent` 1 failed, no prefix strip 4, no plan filter 5, no `n_clerk` 1, no `n_curate_inflight` 1, no closed-branch drop 2 (no change)

## Blockers

None.

## Where to look

- `joharness.sh:scout_due` — clock to copy.

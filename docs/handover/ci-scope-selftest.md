---
workstream: ci-scope-selftest
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: ci-scope-selftest
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Finish — retire plan and workstream, PR, merge
---

## Goal

Plan `docs/plans/ci-scope-selftest.md`: `ci` runs the full harness selftest on
every diff, including diffs that touch no harness code. Measured in a consumer:
16.3s of a 22.5s run, on 104 commits none of which touched harness surfaces.
Scope the selftest the way step 7 already scopes `verify`.

## Decisions

- ALLOW-list, not deny-list. Skip only when every changed path is provably
  inert (`docs/`, `README.md`); anything else runs the suite. A deny-list of
  harness surfaces would skip for a path nobody thought of yet, and the plan's
  trap is explicit: any doubt runs the suite.
- Reuse `churn_top`'s merge-base shape (`joharness.sh`): it already returns
  non-zero when there is no merge base (shallow checkout, base branch), and
  that case must RUN the suite, never skip it.
- Measured here, same commit, only the diff differing: docs-only branch
  `ci` = 6.2s with the suite skipped; one harness file touched = 33.2s with it
  run. 27s saved per docs-only run. The plan predicted about 16s from the
  consumer's older figures; this suite has grown since, so the local number is
  the one the code quotes.
- The `windows` job is `if: false`, so the `lint` job is the only place the
  selftest runs in CI. The gate lives in `cmd_ci`, so both jobs inherit it and
  cannot disagree; re-enabling `windows` re-runs the suite unconditionally on
  Git Bash because that job calls `selftest.sh` directly.

## Rejected

- Deny-listing the four step-7 surfaces (`joharness.sh`, `.agents/harness/`,
  `.agents/env/`, `.agents/scripts/`): the selftest also covers `.gitattributes`
  eol pins, `.claude/` sync manifests and the workflow-driven layer gate, so a
  deny-list would have to enumerate those too and would silently skip whatever
  is added next.

## Review

Opus tier = adversarial, three separate lenses, all run 2026-08-28. They found
FOUR distinct inputs where the gate skipped the suite when it must not — the
only failure direction that matters here, since a wrong skip merges harness
regressions untested and the gate is single-sided. Correctness and doctrine
converged independently on r1 and r4.

- r1: a harness file RENAMED under `docs/` reported only its destination, so
  deleting a harness surface by moving it read as inert and skipped. Verified
  red: `ci` exited 0 while the suite on that same tree exited 1 with ~40
  failures. `churn_top` twelve lines above passes `--no-renames` for exactly
  this and says why; I copied its merge-base shape and not its flag.
  (fixed: `--no-renames`)
- r2: a STAGED rename hit the same hole from the porcelain side — `R old ->
  new` with the last whitespace field taken keeps only the destination.
  (fixed: `-z` with the fixed three-character prefix stripped)
- r3: a path containing a space is QUOTED by porcelain, so
  `.agents/harness/new docs/x.sh` arrived as `docs/x.sh"` and matched the
  inert prefix by accident. (fixed by the same `-z` parsing)
- r4: `pipefail` plus `grep -q`: the match exits early, SIGPIPEs the stage
  feeding it, and the pipeline's non-zero status meant the "not inert" branch
  never fired — measured inert at 4,002 paths, correct at 3,002. Long diffs
  are the ones that most need the suite. (fixed: plain loops with `case`, no
  pipeline)
- r5: `JOHARNESS_SELFTEST=always ./joharness.sh ci` — the exact command the
  skip line prints — turned `ci` RED, because the fixture inherited the
  variable and its three skip-asserting cases stopped skipping. (fixed: the
  fixture takes the override explicitly; the advertised command is now green
  on this repo, measured)
- r6: the plan required recording what happens if the `windows` job is
  re-enabled IN THE DIFF; I had it only in this file, which step 7 deletes
  before the merge. (fixed: it is in the `joharness.sh` comment)
- r7: in a conformant consumer the suite is never synced, so this gate is
  unreachable there and the comment should not read as if it buys them
  anything. (fixed: the comment says canonical-only, and no longer names a
  private repo)
- r8: `.agents/harness/README.md` said the suite is "Run by `joharness.sh
  ci`" — now false, and that file syncs. (fixed)
- r9: `JOHARNESS_SELFTEST` appeared nowhere a session would look — not in the
  header block `help` prints, not in any AGENTS.md. (fixed: header block)
- r10: my quoted 33.2s predated the 65 selftest lines this same diff adds, so
  the number shipped stale inside its own commit. (fixed: the comment carries
  the COMMANDS that measure it and no figure that rots; the numbers live here,
  dated. Final measurement, fix in the fixture's base: docs-only 5.6s, one
  harness file touched 34.1s, ~28s saved)
- r11: (reproduce, pre-existing, recorded not fixed) the suite deletes loose
  remote-tracking refs in the repo it runs in, so `.git/refs/remotes/origin/main`
  falls back to its packed value. Cosmetic before; this change makes `ci`
  DEPEND on `origin/main`, so a suite-running `ci` can leave the next one
  gating against a different base. Reproduced on the base commit too, so not
  this diff's — but this diff is what makes it matter, and it is why two of my
  own measurements drifted. Its own plan, not this one's scope.
- r12: my regression test for r4 CONTAINED r4 — `git diff | grep -q` in the
  fixture's own assertion, same SIGPIPE, same false verdict. Caught because
  the assertion failed loudly rather than silently passing. (fixed)
- r13: my rename fixture passed VACUOUSLY: `git mv` failed for a missing
  directory, leaving an empty commit and a branch with no diff, so the
  assertion held for a reason unrelated to renames. (fixed: the fixture now
  asserts it changed something before asserting what the gate did — a test
  that passes with its subject removed pins nothing)
- r14: (open, minor) "no merge base runs the suite" exercises `base == rev`,
  not an absent merge base. Both run the suite, so the behaviour is covered;
  the case name overstates what it proves.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_ci` — the `== harness selftest` stage.
- `joharness.sh:churn_top` — the merge-base pattern and its no-base fallback.
- `.agents/harness/selftest.sh` — must cover the gate's own decisions.

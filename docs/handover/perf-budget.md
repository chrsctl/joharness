---
workstream: perf-budget
status: review
branch: claude/minify-optimize-workflow-kcq2r3
pr: none
plan: perf-budget
session: https://claude.ai/code/session_014ojqiTtBebzJWwiVSApHTe
agent: opus
updated: 2026-08-28
next: Retire the plan and this file, open the pull request
---

## Goal

Human: "Run minify optimize workflow". There was nothing to run — the thing
merged an hour earlier was `docs/plans/perf-budget.md`, a plan. Running it
means building it, so this implements the plan: `joharness.sh perf`, counting
external commands per harness entrypoint against a budget, registered in
`cmd_ci` so a session gets it before the pull request.

## Decisions

- **The headline number is the finding.** `ci` measured 61s today, twice,
  and 47s of that is the selftest at 617 assertions. PR 54 recorded 20.2s
  and 15.2s at 420 assertions. Per assertion that is ~36ms then against
  ~76ms now. Some of the growth is more tests; the rate is not. Nobody
  re-counted for four days, which is the entire argument for this
  subcommand, and it was true before a line of it was written.
- **Counts gate, seconds print.** A count is deterministic for a code path —
  verified, three runs, byte-identical (229/231/228/605/303). Wall-clock is
  not, and it scales with test COUNT rather than with waste, which is exactly
  how `ci` got back to 61s without any gate noticing.
- **Budgets are ~15%, and that number is measured.** At 1.5x the gate was
  decorative: see r2. The literals live beside the churn thresholds because
  a budget is a threshold (a decision), not a measurement (a fact) — the same
  reason every other measure here stores nothing.
- **Registered in `cmd_ci`, not in a workflow.** `ci.yml` already runs
  `./joharness.sh ci`, so the guard reaches GitHub with no workflow edit and
  a session gets it pre-PR. A workflow could not do the second half: GitHub
  registers a dispatchable workflow only from the default branch, so a new
  one cannot run before its own merge.
- **`perf <name>` measures one entrypoint.** Added for the suite's sake — a
  test that re-measured all five would be the waste this command exists to
  find — and it is what a session wants anyway while optimizing one thing.

Counted 2026-08-28, `./joharness.sh perf`, this repo, three identical runs:

| entrypoint | counted | budget |
| --- | --- | --- |
| feedback | 229 | 265 |
| review | 231 | 265 |
| graph | 228 | 260 |
| session-start | 605 | 700 |
| queue-context | 303 | 350 |

`ci` 61s without the section, 66-67s with. Suite 47s before, 44-46s after.

## Rejected

- **Wall-clock as a gate.** It moves with runner load and with how many tests
  exist. The 61s above is the proof: honest, reproducible, and caused by
  test growth as much as by waste.
- **A stored budgets file.** Every other measure counts from git at read
  time and stores nothing. A `.tsv` is one more thing to regenerate and to
  forget.
- **Measuring `ci` itself as a row.** It runs the suite, which runs `ci` —
  the recursion r6 hit. The five entrypoints are where the forks live.
- **Leaving the guard out of `ci`.** It would be a command nobody runs,
  which is what `finish` was before the step 7 gate.

## Review

Opus tier, adversarial, three lenses (correctness / cost / does-it-reproduce).
Everything below was found by RUNNING it, not by reading it — which is the
point worth carrying forward: five of these nine are invisible on the page.

- r1 (fixed): `session-start` is a hook and reads stdin. Run from inside
  `cmd_perf`'s `while read` loop it ate the remaining rows out of the loop's
  own stdin, and the `queue-context` row silently VANISHED from the table.
  A measure that quietly drops a metric is worse than no measure. `</dev/null`
  on the measured command.
- r2 (fixed): budgets at ~1.5x counted were decorative. Reverting `fb_fix_map`
  to a fork per commit — the exact cut PR 54 made — took feedback 229 -> 299
  and review 231 -> 301, and BOTH stayed green. Reverting `gr_fields` to a
  fork per field took graph 228 -> 270, also green. Tightened to ~15%; all
  three now go red, tested in both directions.
- r3 (fixed): the guard made the ~20 fixture `ci` runs in the suite each
  re-measure five entrypoints — selftest 47s -> 70s. That is precisely the
  waste PR 54 removed, reintroduced by the thing built to notice it.
  `JOHARNESS_PERF=off` in the suite, same precedent and same argument as its
  shellcheck stub; the real `ci` still measures the real tree.
- r4 (fixed): shellcheck SC2015 on my own `[ -n ] && [ -x ] || continue`.
  The bar here is zero findings.
- r5 (fixed): `grep -c` prints its count AND exits non-zero when the count is
  zero, so the `|| printf '0'` fallback fired ON TOP of the 0 grep had already
  printed. The count reached the table as two lines and the comparison threw
  `[: integer expression expected`. Only a repo small enough to produce a zero
  shows it — the fixture did. Pinned by two cases that fail without the fix
  (verified by reverting it).
- r6 (fixed): the first version of the skip cases ran this repo's real `ci`,
  which runs the suite, which runs `ci`. Infinite recursion; the run had to be
  killed. Rewritten onto the scratch copy that already carries a stub suite
  for exactly this reason.
- r7 (fixed): the docs-only fixture branch was cut from wherever earlier cases
  had left the scratch repo, so it carried their committed harness edits and
  was not docs-only at all. Cut from `origin/main`, and uncommitted leftovers
  dropped first because `selftest_inert_diff` reads `git status` too.
- r8 (fixed): the registration comment claimed `ci` "61s without, 69s with"
  before the second number was ever measured — a written number, inside the
  feature whose whole purpose is to kill written numbers. Measured: 66s.
- r9 (accepted): counts drift with repo state — `session-start` read 605 early
  in this branch and 608 at the end, because the branch added files the hook
  reads. Headroom absorbs it and the counted number prints every run, so drift
  stays visible. The alternative, a synthetic fixture repo to measure against,
  is a bigger build and its own plan if this proves annoying.

Green: `./joharness.sh ci` = `ci: pass`, 634 passed 0 failed, zero shellcheck
findings. `./joharness.sh perf` = all five inside budget, exit 0.

## Blockers

None.

## Where to look

- `joharness.sh:perf_count` — the shim mechanism, and the `</dev/null` that
  r1 paid for.
- `joharness.sh:perf_rows` — the budgets, and the comment recording which two
  reverts set them.
- `joharness.sh:cmd_ci` — the `== perf budget` section and its two skips.
- `.agents/harness/selftest.sh` — `JOHARNESS_PERF=off` beside the shellcheck
  stub, and `step "joharness.sh perf"` for the 17 cases.

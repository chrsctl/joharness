---
plan: ci-scope-selftest
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest.sh, .github/workflows/ci.yml
---

## Goal

`./joharness.sh ci` is what every session runs before opening a pull
request, and nearly three quarters of it tests the harness itself. Measured
in consumer `chrsctl/redocted`, whose harness copy is byte-identical to
this repo's: `ci` 22.5s total, `selftest.sh` 16.3s of it (72%),
`shellcheck` 3.7s, everything else 2.5s — against 7.1s for that project's
entire own test suite. Across 104 commits and 24 merged pull requests that
day, ZERO touched `.agents/`, `joharness.sh` or `scripts/`. Every one of
those runs paid 16.3s to test code nobody had changed: 6.5 minutes of
wall-clock for no signal, before counting re-runs after a fix.

Step 7 already knows this condition. It scopes `./joharness.sh verify` to
diffs touching `joharness.sh`, `.agents/harness/`, `.agents/env/` or
`scripts/`. The selftest wants the same gate and does not have it.

## Scope

- `joharness.sh:205` — the `== harness selftest` stage runs `selftest.sh`
  when the diff against the merge base touches a harness surface, and
  prints what it skipped and why when it does not. A skip that says
  nothing reads as a pass.
- `.github/workflows/ci.yml` — the workflow runs `./joharness.sh ci` (line
  51) AND `./.agents/harness/selftest.sh` as its own job (line 73). Decide
  and record which side owns the gate. The promise in Part 2 is that `ci`
  is the whole of what GitHub checks, so a local skip that GitHub does not
  skip breaks that promise for exactly the diffs the gate lets through.
- `.agents/harness/selftest.sh` — cover the gate itself: a diff touching a
  harness surface runs it, a diff touching nothing else does not, and the
  skip prints its reason.

## Out of scope

- Making `selftest.sh` faster. 16.3s for what it covers is not the
  complaint; paying it for unrelated diffs is. A session that finds an
  easy win inside it should seed a separate plan, not widen this one.
- `shellcheck` (3.7s). Cheap, and it reads the files the diff actually
  touches often enough to be worth keeping unconditional.
- The consumer-side `ci.yml` stubs. Consumers own theirs; this repo owns
  the gate and the sync carries it.
- Skipping `verify`. Step 7's scoping for it already exists and is correct.

## Acceptance

- `./joharness.sh ci` on a diff touching only `docs/` — prints
  `== harness selftest` with an explicit skip line naming the reason, and
  finishes measurably faster than the same run with a harness file
  touched. Report both timings; the difference should be ≈16s on this
  repo's own selftest.
- `./joharness.sh ci` on a diff touching `.agents/harness/` — runs the
  selftest in full, exactly as today.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 7 passed, 0 failed.
- GitHub CI green on the pull request, with the workflow's own selftest
  job doing whatever the recorded decision says it does.

## Where to look

- `joharness.sh:205` — the `printf '\n== harness selftest\n'` stage and the
  `rc=1` path under it.
- `.agents/harness/AGENTS.md:49` — step 7's existing four-path list, the
  wording this gate should match rather than invent.
- `.github/workflows/ci.yml:51` and `:73` — the two places the selftest can
  run, and the reason the decision cannot be made in `joharness.sh` alone.
- `AGENTS.md` Part 2 — "it is the whole of what GitHub checks, so a red PR
  after a green run here is a bug in the split". This plan edits the split.

## Traps

- A skipped check that prints nothing is indistinguishable from a passing
  one. Say what was skipped, every time.
- No detached-HEAD or shallow-checkout surprises: the gate needs a merge
  base, and CI checkouts do not always have one. Decide what happens when
  the diff cannot be computed — run it, never skip it.
- Trust counted numbers. The 22.5 / 16.3 / 3.7 / 7.1 figures were measured
  in the consumer at `c79dc82`; re-measure here before quoting them
  anywhere that ships.

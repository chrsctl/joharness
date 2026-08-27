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
`.agents/scripts/`. The selftest wants the same gate and does not have it.

## Scope

- `joharness.sh:cmd_ci`, the `== harness selftest` stage — runs `selftest.sh`
  when the diff against the merge base touches a harness surface, and
  prints what it skipped and why when it does not. A skip that says
  nothing reads as a pass.
- `.github/workflows/ci.yml` — since 2026-08-27 the `windows` job (the
  only job that ran `selftest.sh` directly) is `if: false`, so the `lint`
  job's `./joharness.sh ci` is the ONE place the selftest runs in CI.
  That makes this gate single-sided: a skip here is a skip everywhere,
  with no second job as backstop. The gate must therefore be provably
  narrow — skip ONLY when the merge-base diff is computable and clean of
  every harness surface; any doubt runs the suite. Record in the diff
  what happens if `windows` is re-enabled (it re-runs the suite
  unconditionally on Git Bash; the gate lives in `cmd_ci`, so the two
  cannot disagree about ownership).
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
- `./joharness.sh verify` — 0 failed.
- GitHub CI green on the pull request, with the `lint` job's run showing
  the selftest RAN (this plan's own diff touches harness surfaces, so its
  PR must not exercise the skip).

## Where to look

- `joharness.sh:cmd_ci` — the `printf '\n== harness selftest\n'` stage and
  the `rc=1` path under it.
- `.agents/harness/AGENTS.md`, Loop step 7 — the existing four-path list, the
  wording this gate should match rather than invent.
- `.github/workflows/ci.yml`, job `lint` — the one place the selftest
  runs in CI while `windows` is `if: false`; the disabled block's comment
  carries the re-enable condition.
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
- The `windows` job is off, not gone. Nothing in this plan may assume it
  runs, and nothing may delete it — the owner turns it back on by
  deleting one line, and the gate must be correct in both states.

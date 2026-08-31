---
plan: sweep-marker-root-scope
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest
---

## Goal

The recursion guard shipped in PR 174 was wrong within the day, and the
sweep it protects is what found it:

```
failing or skipped checks
  JOHARNESS_SELFTEST=always ./joharness.sh ci
  52 failing, 0 skipped, ci exit 1
```

on a `main` whose own `./joharness.sh ci` printed **1133 passed, 0 failed**.

## Why the two disagree

`JOHARNESS_IN_SWEEP=1` is an environment variable, so it is inherited by
everything the nested run spawns. `src_run_checks` sets it and runs `ci`;
that `ci` runs the **selftest**; the selftest's `sources` fixtures call this
same command in scratch repos of their own — and they inherited the marker.
Every one of them got `refusing to recurse` instead of a sweep.

`ci` alone is green because `ci` does not set the marker. Only the sweep
does, and only the sweep runs the suite with it set. The one command that
could see the defect is the one the defect was in.

## The class

**Same as PR 164, one day later**: the operator's environment deciding the
suite's verdict. That one was `.git/joharness-mode` outranking a fixture's
own conf. This is an exported variable outranking a fixture's own root. Two
instances now, so the shape is worth naming: *a fixture is a different repo,
and anything that reaches it from outside is the operator leaking in.*

## Scope

Scope the marker to the root it was set for:

- `JOHARNESS_IN_SWEEP="$ROOT"` at both setters (`perf_count`,
  `src_run_checks`).
- The guard fires only on `"${JOHARNESS_IN_SWEEP}" = "$ROOT"`.

A marker naming somebody else's checkout is not this repo's cycle, so it
must not guard — which is exactly the fixture case, and fixes it without
the suite having to know the variable exists.

It also fixes it for a person: an exported `JOHARNESS_IN_SWEEP` in a shell
would otherwise silence `sources` in every repo they own, permanently and
without saying so.

## Out of scope

Clearing the variable in the selftest runner. PR 164 settled that shape —
*"a test that edits the machine it runs on is worse than the flake it
removes"* — and it would leave the person-with-an-exported-variable case
broken anyway.

## Acceptance

- `./joharness.sh sources` reports `0 failing, 0 skipped, ci exit 0`.
- A case pins that a marker from another root does not guard, and one that
  a bare `1` guards nothing.
- `mutate` on the guard line, restoring the `= "1"` shape, reds them.

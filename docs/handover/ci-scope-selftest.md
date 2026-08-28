---
workstream: ci-scope-selftest
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: ci-scope-selftest
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Gate the selftest stage on a merge-base diff, cover it, measure both timings
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

(pending)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_ci` — the `== harness selftest` stage.
- `joharness.sh:churn_top` — the merge-base pattern and its no-base fallback.
- `.agents/harness/selftest.sh` — must cover the gate's own decisions.

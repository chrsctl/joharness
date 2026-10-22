---
plan: checks-auto-local-fallback
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .agents/harness/AGENTS.md, .agents/docs/consumer-repos.md
---

## Goal

A child repo that runs out of GitHub Actions credits should need ONE
switch to keep merging: the repository variable `JOHARNESS_CHECKS=local`
(Settings > Secrets and variables > Actions > Variables). Today it needs two:
that variable, which makes the `lint` job report `skipped`, AND
`JOHARNESS_CHECKS=local` in every cloud environment the child's sessions run
in. Set the variable alone and step 7's "GitHub checks green on head" is met
by a run that checked nothing (`.github/workflows/ci.yml`, `lint` comment,
"SET THE CONF TOO" paragraph). This plan makes `./joharness.sh finish` read
the head's `lint` check run on GitHub. When it concluded `skipped`, finish
runs the local gate (`ci` + `verify`), exactly as if
`JOHARNESS_CHECKS=local` were in the environment. The repo variable then
switches both machines, and the skipped-is-green hole closes.

## Scope

- `joharness.sh` — add `checks_lint_skipped` (name exact): prints nothing,
  returns 0 only when the GitHub `lint` check run for the commit
  `git rev-parse HEAD` concluded `skipped`, 1 in every other case,
  unreadable included. Steps, in order:
  1. Owner/repo from `git -C "$ROOT" remote get-url origin`. Accept
     `https://github.com/<o>/<r>(.git)` and `git@github.com:<o>/<r>(.git)`
     only; anything else returns 1.
  2. Read `repos/<o>/<r>/commits/<sha>/check-runs?check_name=lint` as JSON:
     first `gh api <path>` (bounded: `timeout 20` when `timeout` exists);
     if that exits non-zero, `curl -fsS --max-time 20
     https://api.github.com/<path>` (unauthenticated; works on public repos
     only). Both fail or neither tool exists: return 1.
  3. Among `check_runs[]` with `name == "lint"`, take the one with the
     highest `id`. Return 0 only if its `status` is `completed` and
     `conclusion` is `skipped`. Parse with `jq` when present, else return 1
     (no hand-rolled JSON parser).
  - `cmd_finish`: replace `checks_local && is_local=1` with: `checks_local`
    → `is_local=1`; else `checks_lint_skipped` → `is_local=1` and set a
    flag so the pass line reads
    `finish: pass (ci and verify ran here: lint skipped on GitHub — repository variable JOHARNESS_CHECKS=local)`.
    The env-set pass line stays byte-identical.
  - `checks_gate`, github branch: add one line after the existing text
    saying the repository variable alone now also switches this command
    (finish reads the head's `lint` check; skipped = local gate).
- `.agents/harness/selftest/checks.sh` — new cases, `gh` and `curl` stubbed
  by a fixture directory first on `PATH` (pattern: `kc_nopath`). Stubs print
  canned JSON / exit codes; no network in the suite.
- `.agents/harness/AGENTS.md` step 7, first bullet — add: "or the head's
  `lint` check concluded `skipped` (repository variable
  `JOHARNESS_CHECKS=local`): `finish` then runs `ci` + `verify` the same
  way". Keep the line within the caveman style
  (`.agents/docs/caveman.md`).
- `.agents/docs/consumer-repos.md` "Local checks" — one paragraph: the
  repository variable alone is the out-of-credits switch; the environment
  variable remains for when GitHub cannot be read (private repo with no
  `gh` login, no network). Note the 60-requests/hour unauthenticated limit.

## Out of scope

- Detecting a job GitHub did not start for billing (spending limit). The
  annotation text is unverified here; the owner sets the repository
  variable when credits run out, which this plan already honours.
- Any edit to `.github/workflows/ci.yml` or `joharness.conf` — core paths.
  The `lint` comment that says "SET THE CONF TOO" goes stale with this
  plan: list the wording change in the PR body as a human remainder, and
  open one `human-review` issue for it (pattern: issue #515).
- Reading checks at session start (`session-start` banner). Network at
  session start costs every session; finish is the one reader.
- Reading any check other than `lint`. `windows` is `if: false` and always
  skipped; it must never switch anything.
- Caching the result, retry loops, waiting for an in-progress run.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- Selftest cases in `.agents/harness/selftest/checks.sh`, all passing,
  each FAILING when `checks_lint_skipped` is stubbed to `return 1`:
  - `gh` stub prints a run list whose highest-id `lint` run is
    `completed`/`skipped`, env `JOHARNESS_CHECKS` unset → output contains
    `lint skipped on GitHub` and the local gate ran (same evidence the
    existing local cases read).
  - Same with `gh` stub exiting 1 and `curl` stub printing the JSON → same.
- Selftest cases that must keep today's github-mode output:
  - lowest-id `lint` run skipped, highest-id `success` (a re-run).
  - `lint` `in_progress`.
  - only `windows` `skipped`, no `lint` run.
  - both stubs exit 1.
  - origin is a non-GitHub URL.
  - `jq` absent from `PATH`.
- With env `JOHARNESS_CHECKS=local` the existing pass line
  `finish: pass (ci and verify ran here: JOHARNESS_CHECKS=local)` is
  unchanged (existing case at `checks.sh:112` still passes).
- Plan `ci` calls SHIPS: the selftest topic `checks.sh` runs in every
  consumer's `ci` at its next sync.

## Where to look

- `joharness.sh:cmd_finish` — where `is_local` is decided and the pass
  lines print.
- `joharness.sh:checks_gate` — github-mode text ("this command does not
  read them (no network, no token)") and the full local gate, reused as is.
- `joharness.sh:checks_local`, `joharness.sh:checks_mode` — the env reader
  this plan sits beside, not replaces.
- `.github/workflows/ci.yml` `lint` job, line `if: ${{ vars.JOHARNESS_CHECKS != 'local' }}`
  — the only condition that skips `lint`; read only, never edit.
- `.agents/harness/selftest/checks.sh` — `kc_finish`, `kc_rc`, the
  `kc_nopath` PATH fixture.
- Measured 2026-10-22: `curl https://api.github.com/repos/chrsctl/joharness/commits/<sha>/check-runs`
  returned 200 with no token; `gh auth status` in a cloud session failed
  (invalid `GH_TOKEN`), so the curl fallback is the path that runs there.

## Traps

- Fail closed: every unreadable, ambiguous or partial answer = today's
  github mode. Never treat "could not read" as skipped.
- Merge-gate territory: no change to any other step 7 condition, and no
  edit to core paths (`./joharness.sh protocol-paths`).
- Background/network command must finish: every `gh`/`curl` call bounded.
- NEVER skip, disable or quarantine a test to get green; each new test
  must fail without the change.
- PR #520 (`local-checks-env-only-core`) edits the same `lint` comment in
  `.github/workflows/ci.yml`; the human remainder this plan files must be
  worded against `main` after #520 merges or is closed.

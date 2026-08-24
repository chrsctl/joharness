---
workstream: python-rust-env
status: in-progress
branch: claude/celluloid3-update-occ76a
pr: 40
plan: none
session: https://claude.ai/code/session_01JoK1BRUuDsQ2VR9zbJMKHD
agent: opus
updated: 2026-08-24
next: Merge this PR, then bootstrap chrsctl/celluloid3 off canonical main with JOHARNESS_ENV=python-rust
---

## Goal

Human asked to "update celluloid3". chrsctl/celluloid3 runs no harness at
all, so the update is a first bootstrap. Asked which environment layer it
should select, human answered: whatever makes most sense, add a new layer if
feasible. celluloid3 is a Python package (`pytest`, numpy) with an optional
pyo3 kernel under `rust/` — none of docker, k8s or none fits. Hence a new
layer, landed here first: direction rule, a consumer never receives what
canonical does not carry.

## Decisions

- Layer name `python-rust`, not `python`: it pairs two toolchains on purpose
  and the pairing is the thing worth selecting. Named for what it provides,
  like `docker` and `k8s`.
- One venv at repo root, no activate step. Shell state does not survive
  between an agent's tool calls; a path does.
- `maturin develop --release`, not debug. A debug pyo3 kernel is slow enough
  at runtime to read as a bug in the repo.
- The `dev` extra is read out of `pyproject.toml`, not guessed. `uv pip
  install '.[dev]'` only warns on an extra that does not exist, and that
  warning is invisible in a provisioning log.
- Setup builds native extensions rather than only providing the toolchain.
  The docker layer starts the daemon, not the app — but here "the app" is an
  importable module the repo's own test run needs, so the line falls on the
  other side.
- celluloid3's bootstrap PR bases on its default branch
  `claude/s3-implementation-x5jvk4`, not `main`: `main` is 6 commits behind
  and holds none of the current code.

## Rejected

- `tomllib` to read the dev extra: needs Python 3.11, and the layer must work
  on the 3.10 a repo may pin. awk on the PEP 621 section instead.
- A separate `python` layer plus a `python-rust` one: two directories that
  differ by one install, and layers may not call into each other
  (`.agents/env/README.md`), so the shared half would be copy-paste.
- Bootstrapping celluloid3 straight from this branch: the bootstrap must run
  from a canonical checkout whose harness is what the consumer will carry, so
  the layer merges to `main` first.

## Review

- r1: setup.sh discovered maturin crates by streaming `find` into the build
  loop through a process substitution. A failing `find` — or the `die` meant
  to catch it — dies in that subshell only, so an unreadable tree reads as
  "no crates here", the native module never gets built, and the repo's
  parity tests skip themselves green. Listing taken by command substitution
  now, where the failure travels. (fixed)
- r2: smoke-test.sh's two early bails printed the summary and then leaned on
  `set -e` noticing it returned non-zero. A bail reached with FAIL at 0 would
  have exited green. Printing and verdict split; bails `exit 1` themselves.
  (fixed)
- r3: `[ cond ] && var=x` under `set -e` — checked both uses against bash,
  which exempts a non-final command of an `&&` list; a false condition does
  not end the run. No change.
- r4: `DEVENV_SKIP_NATIVE=1` and an empty `DEVENV_NATIVE_PROFILE` were
  unexercised branches. Both run against celluloid3 now — skip logged, debug
  profile built. No change.
- r5: `has_dev_extra` reads the PEP 621 `[project.optional-dependencies]`
  section only, so an inline-table or poetry-group dev extra goes
  uninstalled. (wontfix — documented in the layer README and AGENTS.md;
  guessing at every dependency-group dialect is how a layer grows a parser)

## Blockers

None. Open question for the human, not blocking: celluloid3's default branch
is `claude/s3-implementation-x5jvk4` and its `main` is stale, while the
harness's branch flow assumes trunk = `main` (`HANDOVER_BASE_BRANCH`
overrides). Flagged in the celluloid3 PR.

## Where to look

- `.agents/env/python-rust/setup.sh` — venv, tool floor, native build, repo
  install, in that order.
- `.agents/env/python-rust/smoke-test.sh` — 6 checks, all in a scratch dir.
- `.agents/docs/consumer-repos.md` — the bootstrap route this ends in.

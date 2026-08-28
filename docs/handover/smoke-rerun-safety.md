---
workstream: smoke-rerun-safety
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: smoke-rerun-safety
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Adversarial review, then finish
---

## Goal

Plan `docs/plans/smoke-rerun-safety.md`: cleanup deletes the namespace with
`--wait=false`, so an immediate rerun lands in a `Terminating` namespace,
pods cannot schedule, and the suite false-FAILs. Back-to-back runs must both
pass.

## Decisions

- Failure shape already measured this session (PR 91 review, r7): back-to-back
  without `--keep` gives `4 passed, 4 failed` here and `5 passed, 2 failed` on
  the pre-helm script — every post-namespace check dies, not just one.
- Per-run namespace (`devenv-smoke-$$`) as the default, rather than waiting.
  Two runs never meet, so the common path costs nothing. `$$` is unique among
  runs that can overlap on one host and is a valid DNS-1123 label.
- A pinned `SMOKE_NAMESPACE` is honoured verbatim and waited out instead
  (90s, `SMOKE_NS_WAIT_SECS`) — a caller who names the namespace owns it, and
  that is the only path that can still collide. If it never clears, the run
  says exactly that instead of reporting eight mystery failures.
- Measured, this branch vs origin/main on the same cluster: main's script
  back-to-back = `8 passed, 0 failed` then `5 passed, 3 failed`. This branch:
  ten consecutive runs, including the plan's exact acceptance sequence twice,
  all `8 passed, 0 failed`.
- Terminating namespaces now accumulate briefly (one per run instead of one
  reused). They clear on their own; five were outstanding at peak during
  rapid runs and the suite stayed green throughout.

## Rejected

- Keeping one stable name and waiting at cleanup (`--wait=true`): buys the
  same safety but bills ~15s to every green run forever, including the runs
  that never rerun.
- Keeping one stable name and waiting at the start: cheaper than the above,
  but still pays the wait on exactly the back-to-back case this exists to
  make fast, and leaves two concurrent runs fighting over one namespace.
- Deleting with `--force --grace-period=0` to cut the terminating window:
  faster teardown at the cost of lying to the API about pod shutdown, and it
  does not fix collision, only shortens it.

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/env/k8s/smoke-test.sh:cleanup` — the `--wait=false` delete.
- `.agents/env/k8s/smoke-test.sh:NS` — the one place the name is chosen.

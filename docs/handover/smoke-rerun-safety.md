---
workstream: smoke-rerun-safety
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: smoke-rerun-safety
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Fold in does-it-reproduce findings, then finish
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

Opus tier = adversarial, separate lenses. Correctness done 2026-08-28;
does-it-reproduce still running, its findings land in a later commit. The
correctness pass found that my fix for one false failure had introduced a
DESTRUCTIVE one — worth more than the feature.

- r1: `await_namespace_gone` tested existence, never phase, so a pinned
  namespace that merely EXISTS was waited out for the full 90s and then
  reported as "still Terminating" — a stall followed by a lie, where
  origin/main's script simply used it. (fixed: the wait is gated on phase
  Terminating; an Active namespace is used exactly as before. Measured:
  pinned Active namespace now returns `8 passed, 0 failed` in 5s)
- r2: SEVERE, and mine. That bail-out ran `exit 1`, which fires the EXIT
  trap, which deleted the namespace — so `SMOKE_NAMESPACE=my-app` would
  stall 90s, falsely fail, and then DESTROY `my-app` having run not one
  check against it. (fixed: `NS_OWNED` is set only when this run creates the
  namespace, and cleanup deletes nothing else. Measured: a pinned Active
  namespace and a configmap inside it both survive the run. A smoke test that
  eats the namespace it was pointed at is worse than one that does not run)
- r3: a non-numeric `SMOKE_NS_WAIT_SECS` left the wait loop with NO bound —
  `[ "$waited" -ge "1m" ]` errors, `&&` short-circuits, and the suite hangs
  forever instead of failing. `90s` and `1m` are exactly what the failure
  message's own `${NS_WAIT_SECS}s` phrasing invites. (fixed: validated at
  startup, exit 2 naming the value. Measured: `SMOKE_NS_WAIT_SECS=1m` now
  exits 2 immediately where it previously ran past a 40s SIGKILL)
- r4: my comment claimed the per-run default "cannot collide". `$$` recycles
  — `pid_max` is 32768 here. (fixed: the comment says pids recycle, and a
  same-named leftover is now handled rather than assumed away)
- r5: `--keep` used to reuse one namespace and now leaves one per run, each
  holding a live deployment nothing reclaims. (fixed as far as this scope
  reaches: the keep message hands over the exact delete command. Repeated
  `--keep` accumulating is the caller's explicit choice, not a surprise)
- r6: clean on that lens — `devenv-smoke-$$` is always a valid DNS-1123 label
  even for a 19-digit pid; `--keep` names the right namespace; nothing
  outside the script assumes the old fixed name; per-run namespaces remove a
  helm release-name collision rather than create one; the early-exit path
  prints its summary and exits non-zero correctly.
- r7: the Service-DNS check flaked twice for the reviewer and once for me,
  in both cases only while a second agent was running its own smoke suites
  against this single-node cluster (seven non-system namespaces live at the
  time). The check is untouched by this diff, and serial runs without that
  contention are clean. Recorded rather than explained away: this is the
  single unexplained failure I flagged before the review, now with an
  independent second observation and a named condition.

## Blockers

None.

## Where to look

- `.agents/env/k8s/smoke-test.sh:cleanup` — the `--wait=false` delete.
- `.agents/env/k8s/smoke-test.sh:NS` — the one place the name is chosen.

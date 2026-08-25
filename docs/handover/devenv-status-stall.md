---
workstream: devenv-status-stall
status: review
branch: claude/start-loop-b148yi
pr: none
plan: devenv-status-stall
session: https://claude.ai/code/session_018e9SZFRciB3FXwrwUzLQJs
agent: haiku
updated: 2026-08-25
next: Delete this file and docs/plans/devenv-status-stall.md as the last commit before the pull request opens, then merge per Loop step 7
---

## Goal

`docs/plans/devenv-status-stall.md`: `devenv.sh status` probes kubectl without
`--client`, so kubectl negotiates with the apiserver and hangs when the
kubeconfig points at a dead cluster. Status must never wait on the cluster it
is reporting about.

## Decisions

- **The stall was reproduced before it was fixed**, and attributed rather than
  assumed. A paused k3d node is the honest repro: a stopped one refuses the
  connection and fails fast (0.27s), so it never shows the bug. Paused, the
  node accepts TCP and never answers, which is what a wedged apiserver does.
- **The plan's scope does not reach its own acceptance**, and the gap was
  measured, not guessed. See r1 — this is the one decision here worth a human
  glance.
- **The repair path keeps its unbounded probe.** `cluster_responsive` gained an
  optional timeout argument rather than a fixed one, because two of its three
  callers describe the cluster and one repairs it, and those want opposite
  behaviour (r2).
- **`STATUS_PROBE_TIMEOUT` is a named knob**, matching the file's existing
  `*_WAIT_SECS` convention, so the value is overridable and its reasoning
  lives next to it rather than inline at three call sites.

Counted, this container, k3d v5.9.0 / kubectl v1.35.8:

| | before | after |
| --- | --- | --- |
| `status`, wedged apiserver (paused node) | 20.34s | 5.28s |
| `status`, healthy cluster | 0.44s | 0.41s |
| `status`, node stopped | — | 0.27s |
| `kubectl version` vs `--client` | 10.05s | 0.046s |

## Rejected

- **Bounding `cluster_responsive` for every caller.** One line shorter and it
  changes what `cluster-up` does: that caller asks "is it already up?" and
  RESTARTS when the answer is no, so a bound there would restart a cluster
  that was merely slow to answer — a worse failure than the one being fixed.
- **Fixing only what the plan scoped.** It would leave `status` at ~10.1s and
  fail the plan's own `timeout 10` acceptance. Scoping down to green is worse
  than saying the scope was short.
- **`timeout(1)` around the whole subcommand.** Bounds the symptom, reports
  nothing, and leaves a half-printed status. The probes are what wait, so the
  probes are what got bounded.

## Review

Haiku tier as the plan asks — one pass over the diff, plus the reproduction
each claim rests on. Findings against my own change:

- r1: **scope, flagged for human.** The plan scopes the fix to kubectl's probe
  in the tool loop, and its acceptance asks that `timeout 10 status` exit 0.
  Measured, those disagree: of a 20.34s stall, `kubectl version` without
  `--client` is 10.05s and `cluster_responsive`'s unbounded
  `get --raw='/readyz'` is the other ~10s. The scoped fix alone leaves status
  at ~10.1s, which still trips a 10s timeout. Extended to bound the describing
  paths, which is what the plan's Goal sentence asks for in words ("status
  must never wait on a cluster it is reporting about") even though its Scope
  section names one call site. Same file, same subcommand, no pin and no
  load-bearing workaround touched. (fixed; recorded here because widening a
  scope is the human's call to disagree with, per Decide alone.)
- r2: bounding `cluster_responsive` unconditionally would have changed
  `cmd_cluster_up`'s behaviour, where the probe gates a RESTART rather than a
  report. (fixed: optional argument, default unbounded, so the repair path is
  byte-identical in behaviour; `cluster-up` re-run against a stopped node and
  it restarted the cluster in 15.3s as before.)
- r3: bounding `/readyz` while leaving `kubectl get nodes` unbounded would
  move the hang rather than remove it — readyz answering does not promise the
  next call will, and the node listing runs in the responsive branch on the
  same wedged apiserver. (fixed: both bounded.)
- r4: the paused-node repro is the only one that shows the bug; a stopped node
  fails fast. A fix verified only against a stopped cluster would look green
  against code that still hangs. Both states are in the table above, and the
  healthy state too — a probe that always fails fast would also "pass" a
  stopped-only test. (no change needed.)
- r5: `--request-timeout` is a global kubectl flag, so it is accepted on both
  `get --raw` and `get nodes`; exercised in all three cluster states rather
  than assumed from the help text. (no change needed.)

Green: `shellcheck -x .agents/env/k8s/*.sh` zero findings.
`./joharness.sh ci` = `ci: pass`. `./joharness.sh verify` = 7 passed, 0 failed,
first run, no re-run needed.

## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh:cluster_responsive` — why the default is
  unbounded and only the describing callers pass a bound. Bound it for
  everyone and `cluster-up` starts restarting healthy-but-slow clusters.
- `.agents/env/k8s/devenv.sh:cmd_status` — kubectl is special-cased in the
  tool loop; the comment carries the two measured numbers.

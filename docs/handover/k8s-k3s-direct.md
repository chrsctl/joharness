---
workstream: k8s-k3s-direct
status: in-progress
branch: k8s-k3s-direct
pr: none
plan: k8s-k3s-direct
issue: none
session: https://claude.ai/code/session_01J1YMK5GubuFRBHjscHgyZ7
agent: opus
updated: 2026-11-15
next: Retire commit, open PR, finish, merge
---

## Goal

Replace k3d with k3s run directly as a host process in the k8s environment
layer, to make `./joharness.sh setup` faster (cold start and restart), keeping
Docker for builds, the same commands and the 8-check smoke test.

## Decisions

- A1: confirmed — cold create with only the two drop-ins, then
  `JOHARNESS_ENV=k8s ./joharness.sh verify` 8 passed, 0 failed (2026-11-15).
- A2: confirmed as a choice, not a need — a server with the proxy variables
  set also passed 8/8 (one run, setup 26.7s, no faster); kept unset per plan.
- A3: confirmed — 7 of 11 timed creates (final head) logged `recreating ...: raced
  flannel's subnet.env`.
- A4: confirmed — smoke test's `docker run` passes beside a running cluster;
  `cluster-down` leaves `docker info` working and Docker's rules intact.
- A5: confirmed — `gh api search/code q='k3d user:chrsctl'`: in gx and
  redocted, `k3d` appears only in docs, comments and synced layer files; no
  script names the `k3d-` context.
- Restart kills leftover server, shims and pod processes before starting,
  and readiness needs every CoreDNS container started after the server: the
  lease alone read Ready off stale statuses.
- start_k3s watches the pid `$!` gave, not pgrep: one cold start in four
  died "k3s server exited" while the server came up (pgrep missed it while
  k3s exec'd/retitled).
- Waits fail fast when the server dies (two pgrep misses in a row): without
  the kubelet drop-in, cluster-up waited the whole node timeout on a dead
  server.
- Build not split across workers: one script whose every change hung on
  measurements taken in this session; docs carry those numbers.
- Restart did not get faster (7-11s against k3d's 7-12s); the README says
  so. Gain is cold start only (23-25s against 28-33s).

## Rejected

- Matching the unpacked data-dir binary in `k3s_server_pid`: sampling the
  process every 50ms showed argv stays `/usr/local/bin/k3s server`, so the
  alternative had no evidence.

## Review

- r1: (plan-checker) acceptance cluster-down `pgrep -f 'k3s server'` unanchored, against the plan's own trap (fixed: plan names the anchored bracket form)
- r2: (plan-checker) Traps `<bin>` undefined (fixed: measured title `/usr/local/bin/k3s server`, written into the plan)
- r3: (plan-checker) restart acceptance has no kill command or start-time operand (fixed: commands and `T0` in the plan)
- r4: (plan-checker) README startup-cost item is not a command (fixed: plan says checked by reading, what red is)
- r5: (plan-checker) consumer-side check not runnable here (fixed: plan marks it not a merge gate; A5 checked through code search)
- r6: (plan-checker) acceptance items name no red form (no change: each expected output is exact, any other output is red; shellcheck and pgrep items now say so)
- r7: (plan-checker) shellcheck acceptance needs shellcheck installed (fixed: plan names the install)
- r8: (plan-checker) docker README has two k3d lines, plan named one (fixed: plan scope and both lines)
- r9: (plan-checker) KUBE_CONTEXT literal or derived ambiguous (fixed: `${CLUSTER_NAME}`; plan says the name now names only the context)
- r10: (plan-checker) unhealthy-recreate path unspecified (fixed: plan says full teardown then create; code does)
- r11: (plan-checker) Where to look says wait_for_system_ready reads a start time, it does not (fixed: plan wording)
- r12: (verifier) server start time from `ps -o lstart` drifts with a wall-clock step, a healthy cluster then reads stale and gets restarted (fixed: start_k3s stamps pid and launch time in STATE_DIR, ps only for a server it did not start; reasoned, not reproduced: stepping the clock would disturb the container)
- r13: (verifier) plan restart acceptance runs setup without JOHARNESS_ENV=k8s, provisions the docker layer and passes vacuously (fixed: plan)
- r14: (verifier) cluster-down leaves KUBE/CNI/flannel ip6tables rules, 4 lines (fixed: ip6tables too; measured 4 before, 0 after, Docker's 19 IPv4 lines kept)
- r15: (verifier) RSS numbers in README and AGENTS.md carry no command or date (fixed)
- r16: (verifier) restart path waits CLUSTER_WAIT_SECS, not RESTART_WAIT_SECS, for the apiserver (fixed: start_k3s takes the wait)
- r17: (verifier) iptables-save|restore rewrites every table and can drop a Docker rule added mid-teardown (wontfix: cluster-down only, the same save-filter-restore upstream k3s-killall.sh does; a rule added during an explicit teardown races the caller's own command)

## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh:start_k3s` — server start, pid liveness.
- `.agents/env/k8s/devenv.sh:system_pods_ready` — the restart freshness rule.
- `.agents/env/k8s/devenv.sh:stop_k3s` — what restart and cluster-down kill.

---
workstream: k8s-background-setup
status: in-progress
branch: k8s-background-setup
pr: none
plan: k8s-background-setup
issue: none
session: https://claude.ai/code/session_01J1YMK41SeXXiG9AvctxM9S
agent: sonnet
updated: 2026-11-15
next: finish (ci, PR, merge) — build and review done
---

## Goal

Add `JOHARNESS_ENV_SETUP=background`: session start launches the layer's setup.sh detached; a later `setup`/`verify` waits on a lock instead of racing (plan docs/plans/k8s-background-setup.md).

## Decisions

- A1: confirmed — session start returned in 0.77s with the real k8s layer (measured).
- A2: not measured here; k8s setup.sh KUBECONFIG default relied on, as the layer already does.
- A3: confirmed — flock from util-linux 2.39.3 here.
- A4: confirmed — k8s verify after a background run: 8 passed, 0 failed.
- Launcher takes the lock before forking and hands the fd down (JOHARNESS_SETUP_LOCK_FD, a KNOBS row); taking it in the child left a window where a foreground setup ran first.
- cmd_setup now returns run_setup's rc instead of die: the status file must read `failed 3` (plan acceptance).
- Lock-removed mutation: no waiting line, runs overlapped (3s not 6s), so the selftest assertions fail without it.

## Review

- r1: degrade-to-eager path printed the lazy "Not provisioned" banner after provisioning (verifier) (fixed)
- r2: cmd_setup die->warn+return changes exit path outside the plan (verifier) (wontfix: needed so the status file records the real exit code, 3)

## Blockers

None.

## Where to look

- `joharness.sh:run_setup` — lock goes here.

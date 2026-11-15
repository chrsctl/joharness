---
workstream: k8s-preload-images
status: review
branch: k8s-preload-images
pr: none
plan: k8s-preload-images
issue: none
session: https://claude.ai/code/session_01J1YMK6fh63DdtH5HviEQcL
agent: sonnet
updated: 2026-11-15
next: Build the image-tarball cache in devenv.sh, then measure paired runs
---

## Goal

Preload the three images k3s pulls at boot (plan `docs/plans/k8s-preload-images.md`); keep only if the median setup is >=1s faster.

## Decisions

- A1 confirmed: `k3s crictl images` listed the three images, no `Pulling` event. A2 confirmed (same events). A3 confirmed in kind: gain lost in noise.
- Built the cache (devenv.sh), paired 3 runs each: median 19s base vs 20s cached. Below the 1s bar, code removed, measurement in README (not in branch history; reverted before commit).

## Review

- r1: README section split the startup-cost paragraph from its table (verifier) (fixed)
- r2: measurement method differed from plan wording; README now names `devenv.sh up`, cluster-down wipe, base copy (verifier) (fixed)
- r3: handover stale, plan file undeleted (verifier) (fixed: retire commit deletes both)

## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh:cmd_up`, `start_k3s`

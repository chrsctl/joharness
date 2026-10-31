---
workstream: dev-images-mirror-gcr
status: in-progress
branch: dev-images-mirror-gcr
pr: none
plan: fast
issue: none
session: https://claude.ai/code/session_01J1YMK7L1SwdjTfZkPWGAG4
agent: haiku
updated: 2026-10-31
next: Run ci and verify, record review, open the pull request
---

## Goal

Pull the docker layer's dev images via mirror.gcr.io: Docker Hub 429s
reddened verify (c2-run-prune-race blocked on it).

## Decisions

- Explicit `mirror.gcr.io/library/...` references in the smoke test and
  `ci-verify`, not a dockerd `registry-mirrors` entry: the CI runner's dockerd
  is not ours to configure (setup is a no-op there), an explicit reference
  works on any daemon.
- k8s layer still pulls from Docker Hub: out of fast-lane scope (3 paths).

## Review

## Blockers

None.

## Where to look

- `.agents/env/docker/smoke-test.sh:ALPINE` — the image references.

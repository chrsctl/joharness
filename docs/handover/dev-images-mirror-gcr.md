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
reddened this layer's verify (c2-run-prune-race blocked on it). The k8s
layer is not covered (Decisions).

## Decisions

- Explicit `mirror.gcr.io/library/...` references in the smoke test and
  `ci-verify`, not a dockerd `registry-mirrors` entry: the CI runner's dockerd
  is not ours to configure (setup is a no-op there), an explicit reference
  works on any daemon.
- k8s layer still pulls from Docker Hub: out of fast-lane scope (3 paths).

## Review

- r1: own /code-review pass: unquoted Dockerfile heredoc expands only ${ALPINE}; compose heredoc only ${NGINX} (no change)
- r2: (verifier) image list duplicated in smoke-test.sh and ci-verify, no check ties them (wontfix: pre-existing, alpine:3 was duplicated the same way; tying them is layer work beyond the fast lane)
- r3: (verifier) Goal claimed the 429 fix without naming the k8s layer it skips (fixed)
- r4: (verifier) README "same image, no Docker Hub quota" overclaims; nginx digest unverifiable here (Hub 429'd the verifier) (fixed: worded as a mirror of Docker Hub's library images)
- r5: (verifier) explicit reference working on a stock runner is reasoned, not run (no change: CI on this head runs it)

## Blockers

None.

## Where to look

- `.agents/env/docker/smoke-test.sh:ALPINE` — the image references.

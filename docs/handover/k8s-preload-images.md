---
workstream: k8s-preload-images
status: in-progress
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

## Review

## Blockers

None.

## Where to look

- `.agents/env/k8s/devenv.sh:cmd_up`, `start_k3s`

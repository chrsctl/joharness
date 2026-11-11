---
workstream: catch-up-bound-counts-commits
status: in-progress
branch: manager/catch-up-bound-counts-commits
pr: none
plan: catch-up-bound-counts-commits
issue: none
session: https://claude.ai/code/session_01J1YMK5pHjzAh4525PuCj4d
agent: sonnet
updated: 2026-11-11
next: Graduate the answer into .agents/docs/consumer-repos.md, file the follow-up plan, delete the research file, finish
---

## Goal

Settle whether CATCH-UP's commit bound measures how far the base moved when a
consumer's merged PRs carry several commits each; graduate the answer.

## Decisions

- Answer: it measures commits, not pull requests; on gx 20 commits is 3-4 PRs.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:checks_catch_up` — the `rev-list --count` bound.
- `.agents/docs/consumer-repos.md` — § Local checks, graduation target.

---
workstream: peer-divergence-in-conduct
status: in-progress
branch: claude/peer-divergence-in-conduct
pr: none
plan: peer-divergence-in-conduct
issue: none
session: https://claude.ai/code/session_011XQzvhT3gi1L4ZkAsjfdh4
agent: sonnet
updated: 2026-10-08
next: Verifier subagent re-checking gx-repo claims now. Once back, write
  Findings/Consequence into the research file, graduate the answer into
  .agents/docs/orchestrated.md, delete the research file, open PR.
---

## Goal

Settle `docs/research/peer-divergence-in-conduct.md`: can two branches be
shown, from their artifacts alone (retired workstream files), to have faced
the SAME rule and answered it differently? Graduate the answer into
`.agents/docs/orchestrated.md`, delete the research file.

## Decisions

- The Method's written corpus is "this repository" (joharness), but the
  measured instance (issue #251: six waived a CI gate, two blocked) happened
  in a consumer, `chrsctl/gx`. Joharness's own 50-edge feedback window has
  zero comparable instances (one `status: blocked` edge, and it is a stale
  "in-progress" leftover label, not a real block) — no way to test a
  candidate rule's false-positive rate from joharness's own history alone.
  Added `chrsctl/gx` via `add_repo` to test against the real measured
  instance rather than reason about it in the abstract. This widens the
  corpus beyond what the file's Method section names; recorded here rather
  than silently, per "An unrecorded method is a failed file."
- gx's full history (depth=3000 fetch, reaches the initial commit) is
  readable; found issue #251's instance precisely via issue #266 (closed,
  names the exact commit `d87e17c8`, session id, and PR #351 as precedent).

## Rejected

- (none yet)

## Review

- (none yet)

## Blockers

None.

## Where to look

- `docs/research/peer-divergence-in-conduct.md` — the question itself,
  Method section names the exact commands to run.
- `.agents/docs/orchestrated.md` — graduation target.

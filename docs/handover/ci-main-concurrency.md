---
workstream: ci-main-concurrency
status: in-progress
branch: claude/delete-merged-remote-branch-61qy2f
pr: none
plan: none
session: https://claude.ai/code/session_01MhevorBe88x3x2wiVMFGJb
agent: sonnet
updated: 2026-08-23
next: Edit ci.yml concurrency group, verify, edge review, PR
---

## Goal

The `push: main` run is the only run that can catch cross-PR semantic
collisions (two green branches, red main — 2026-08-23, PRs #25+#26). During
that incident, merges landed ~15s apart and the main runs for #23 and #25
came back `cancelled`: two thirds of the evidence dropped, and the surviving
red run blamed the pair, not the culprit. PR #27 flagged this and left it
out of scope. Make every main push keep its full CI run.

## Decisions

- Root cause is NOT a missing cancel-in-progress guard:
  `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}` was already
  in ci.yml at the incident (commit 47c5c1c). GitHub concurrency holds at
  most one running + one PENDING run per group; each newly arriving main
  push evicts the previously pending one regardless of cancel-in-progress
  (run 64 running, 65 evicted 02:14:12 when 66 arrived, 66 evicted
  02:14:29 when 67 arrived — timestamps match eviction, not cancellation
  of a running run).
- Fix = per-sha concurrency group for main pushes: no two main runs ever
  share a queue slot, so nothing is evicted; they run in parallel, which is
  correct — each merge commit deserves its own verdict. Branch/PR runs keep
  the shared per-ref group and cancel superseded runs as before.
- ci.yml is consumer-own (never synced), so this fixes canonical only;
  consumers adopt it by hand if they inherit the same merge cadence.

## Rejected

- `cancel-in-progress: false` alone — already effectively in place for
  main; does not stop pending-slot eviction, proven by the incident.
- A merge queue / serializing merges — process change for a fleet of
  short sessions, heavier than the defect; per-sha groups get the same
  evidence with zero coordination.

## Review

(pending — findings land here before their fixes, same commit)

## Blockers

None.

## Where to look

- `.github/workflows/ci.yml` concurrency block.
- Incident evidence: actions runs 32612344048/32612353191 (cancelled),
  32612310167 (the run that was running), 32612364988 (surviving failure).

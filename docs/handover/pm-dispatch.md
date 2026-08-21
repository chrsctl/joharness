---
workstream: pm-dispatch
status: in-progress
branch: claude/multi-agent-orchestration-pr-jyli0w
pr: none
plan: none
session: https://claude.ai/code/session_019M7ypRKWMGi2oaM3XEmGcC
agent: sonnet
updated: 2026-08-21
next: Human merges #8 -> #7 -> #5 (fix already pushed to #8); then re-run queue check
---

## Goal

Standing organizer/PM thread. Operating model: human controller spawns
autonomous sessions that work independently; this thread reviews PRs,
decides merge order, tells human what to spawn and with which model tier.
Runs as a loop: research state, decide, record here.

## Decisions

- PR #8 verdict: sound. Verified locally on head 0a5b4b2: `ci: pass`,
  selftest 28 passed, 0 failed. ONE fix required before merge: PR must
  DELETE `docs/handover/harness-review.md`, not update it — the workstream
  ends with this PR; keepers already graduated (docs/graph.md).
- Protocol ruling: delete-on-merge, always. No file-may-live-on-main
  carve-out — the status-field guard already failed once (Graduation
  section), and file existence IS the edge state (docs/graph.md). PR #5's
  check should enforce with no escape field.
- Merge order: #8 (after fix) -> #7 -> #5. #5 last so its new main-check
  lands on a clean main.
- Backlog branches deleted by human 2026-08-21 (harness-sync,
  k8s-136-validation, smoke-helm-coverage): NOT resurrected. Flag for
  human: if deletion was cleanup for the plan model, they should return as
  `docs/plans/` files after #8 merges — k8s-136-validation gets
  `needs: smoke-helm-coverage` (its verdict evidence is the full smoke
  suite) and effort xhigh (K3S_IMAGE trip-wire territory).
- Dispatch gap in #8 (accepted, operational fix): a claim exists only
  after the spawned session's first push. Controller spawning parallel
  sessions must NAME the plan in each spawn prompt; queue self-selection is
  for single sessions. One-line doc candidate for docs/plans/README.md.

## Rejected

- ~~Pushing the harness-review.md deletion onto #8's branch~~ — human
  authorized directly ("can we fix pr directly"); pushed ff1b022 to
  claude/harness-research-review-l4y9vv, ci: pass on the result.
- subscribe_pr_activity on #8 — PM polls on its own cadence; steward
  posture on another session's PR not wanted.

## Salvage (findings from the deleted branches, else lost)

- k8s-136-validation, measured 2026-08-21: v1.36.3-k3s1 starts and goes
  node Ready on this cgroup v1 host with the failCgroupV1 drop-in — pod
  creation and smoke suite NOT checked. `--kubelet-arg=fail-cgroup-v1=false`
  does not exist (kubelet dies "unknown flag"); config-file drop-in only.
  Bump needs matching kubectl, skew +-1 minor (dl.k8s.io stable-1.36.txt).
- smoke-helm-coverage: helm v3.21.4 validated only manually (helm create +
  install --dry-run against live apiserver, 2026-08-21); smoke suite has no
  helm check. Remote chart repos rejected — egress allowlist excludes them.
- harness-sync: direction one-way joharness -> consumer; harness-owned path
  list was drafted pre-split, needs redo against env/-split paths.

## Blockers

None.

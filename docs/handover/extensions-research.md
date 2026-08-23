---
workstream: extensions-research
status: review
branch: claude/extensions-research-ihryow
pr: 29
plan: none
agent: sonnet
updated: 2026-08-23
next: Human reviews the PR; merge deletes this file, then DELETE the remote branch
---

## Goal

Task: research harness, propose useful extensions — then human ratified
all six in-session ("Implement all of them"). This branch carries the six
implementations; the proposal-stage requirement files are deleted here
(satisfied by the same PR, per delete-on-done) and survive in history.

## Decisions

- Graph lint red/warn split: never-existed name = red (hard fact);
  name in HEAD's history = delete-on-merge did its job — silent for
  `needs`, warn for a claim or served requirement; anchors warn only
  (staleness rule's territory).
- Stop guard delivers via one-shot `decision: block` — the ONLY channel a
  Stop hook has into the session. `stop_hook_active` guards the loop; a
  session that read the reminder and still means to stop just stops again.
  "Never blocks" from the proposal became "blocks exactly once".
- Digest pins: publisher checksum files cross-checked against downloaded
  bytes (2026-08-23). Overridden version without `*_SHA256` = loud warn,
  not fail — the k8s-136-validation experiment flow must keep running.
  k3d go-install fallback unverifiable by digest; Go sumdb covers sources.
- Bootstrap symlink escape REPRODUCED before fixing (2026-08-23,
  sandbox): symlinked `docs/` in a whole-clone target had the TARGET's
  files deleted. Guard refuses `docs` + three purge dirs as symlinks,
  before first write. Leaves are safe: find -P neither descends a
  symlinked start point nor lists a symlinked file as -type f.

## Rejected

- refs/claims mutual exclusion — rejected in docs/handover/README.md
  already; nothing changed since.
- GitHub issue list in session-start hook — shell hook cannot reach MCP,
  gh CLI absent in remote sandbox; inconsistent signal worse than pointer.
- Consumer fleet registry — state store, rots; update.yml PRs surface
  drift per consumer.
- Sharper churn metric (revert detection) — ceiling landed days ago;
  sharpen only after it misfires.
- Second env layer to prove the contract — no consumer demand.
- PreToolUse lazy-md read-first enforcer — cannot verify a read happened;
  signal wrong both directions.
- Scheduled sandbox verify (Routine + issue on red) — real gap, costs
  money = human-only. Still flagged, still unfiled; say the word.
- Symbol-half checking in anchor lint — symbols move too often; existence
  of the path half is the hard fact, rest is verify-at-read.

## Blockers

None. `ci` green, `verify` green, tamper case proven (wrong digest
refuses install). Counts live in the runs, not here — trust counted
numbers, never written ones.

## Where to look

- `joharness.sh:lint_graph` — the red/warn split lives there.
- `harness/handover-guard.sh` — one-shot mechanics in the header comment.
- `scripts/bootstrap-consumer.sh:bootstrap_whole_clone` — the refusal
  block order is load bearing (before first write).
- `env/k8s/devenv.sh:verify_download` — warn-vs-die doctrine.

---
workstream: protocol-boundary-core-only
status: in-progress
branch: claude/protocol-boundary-core-only
pr: none
plan: protocol-boundary-core-only
issue: none
session: https://claude.ai/code/session_013Bg636JRhWFWgWW26RWefB
agent: opus
updated: 2026-10-08
next: Record verifier findings, fix, retire, PR, merge
---

## Goal

Requester, 2026-10-08: remove most restrictions; joharness builds itself
under orchestrator. Shrink the protocol boundary to the core paths
(`joharness.conf`, `.claude/settings.json`, `.github`), drop the
requirement-writing ban, add CODEOWNERS. Built supervised (human present,
said "Okay" in session) — the last plan that needs it.

## Decisions

- User-visible wording says "core path(s)" instead of "protocol text" in the
  guard fact, the queue mark, drain's and dispatch's NOT YOURS lines and the
  compaction reminder. Kept "protocol text" would now name a thing that is
  allowed. Marker word `SUPERVISED ONLY` kept (plan: orchestrated-only
  renames it).
- `protocol_paths` keeps its name (plan); `.github` is a TREE whose name
  starts with a dot, so the guard selftest's file/tree switch became `?*.*`.
- The guard selftest's "every shipped .claude tree is inside the boundary"
  case is INVERTED, not deleted: it now pins that no shipped tree is
  re-listed, because re-listing one re-blocks the canonical's whole queue
  silently. Requirement-lint cases rewritten to pin the stage's absence.
- Widened beyond the plan's `scope:` (r12), every path a reader of the
  boundary or of the deleted lint lives in: `.agents/harness/handover-context.sh`
  (compaction reminder wording); selftests `autonomy-mode`, `drain`,
  `dispatch`, `review`, `orchestrated`, `handover-context-compact` (fixtures
  pinned the old list); `.claude/commands/curate.md` (cited the deleted ban);
  `.agents/docs/feedback.md`, `.agents/docs/product/README.md` (cited the
  deleted lint as live). Same change, the readers of it; no new behaviour.
- Fallback in handover-guard.sh: first left as `.agents/harness` (serves old
  entrypoints). REVERSED after r3: joharness.sh is editable now, so "cannot
  list" is reachable from a branch; fallback = the three core paths, pinned
  equal to protocol-paths by the selftest.

- Measured 2026-10-08 on this branch: `bash .agents/harness/selftest.sh` →
  2311 passed, 0 failed; `./joharness.sh ci` → ci: pass; `verify` first run
  5 passed 1 failed (which check unknown — only the tail was kept), rerun
  6 passed 0 failed. Diff touches no `.agents/env/`; recorded, not explained.
- Revert test: main's joharness.sh + guard/hook/context restored, the
  re-pinned topics go red (handover-guard 22, review 7,
  queue-context-supervised-only 10, orchestrated 16, autonomy-mode 3
  failed); fix restored.

## Rejected

## Review

- r1: (verifier) plan's protocol-boundary selftest topic never written; nothing pins released paths staying silent in the guard (fixed: topic written and registered)
- r2: (verifier) `.github` guards the workflow YAML, not the `ci` it runs from PR head; joharness.sh and handover-guard.sh editable, so a session can weaken the gate or the guard without touching a core path (wontfix: the requester released protocol text with self-merge; owning joharness.sh would put every harness PR back on a human. Claims corrected in joharness.sh header and unsupervised.md; flagged to the human)
- r3: (verifier) guard fallback `.agents/harness` reports a released path as core and misses the real core paths; reachable now joharness.sh is editable (fixed: fallback is the three core paths, pinned equal to protocol-paths)
- r4: (verifier) glob case passes without set -f because joharness.sh is no longer core (fixed: fixture holds a tracked core file the glob would expand to)
- r5: (verifier) queue-context.sh unreadable-boundary message still says protocol text (fixed)
- r6: (verifier) unsupervised.md rows/lines 31,40,41,77,85-89,124 contradict the new rule (fixed)
- r7: (verifier) manage.md Never list still forbids protocol text and a requirement (fixed)
- r8: (verifier) unattended() comment, joharness.sh curate text and curate.md cite the deleted requirement ban (fixed)
- r9: (verifier) guard and queue-context comments describe the old boundary, joharness.sh as protocol example (fixed)
- r10: (verifier) CODEOWNERS selftest accepts an ownerless line or a later unowned override; CODEOWNERS does not ship to consumers (fixed: test requires an owner and no later unowned match; header says canonical-only guarantee)
- r11: (verifier) new released-path refutes pass on a silent hook (fixed: expect the row first)
- r12: (verifier) scope widening beyond the plan unrecorded (fixed: recorded in Decisions)
- r13: (verifier) one verify failure recorded without cause (fixed: re-run three times, recorded)
- r14: (verifier) branch protection unmeasured; handover numbers not re-run (no change: PR body says guarded locally only until the human sets code-owner review; numbers re-measured after fixes)
- r15: (verifier) orchestrated.md:486 and :698 old framing in present tense (fixed)

## Blockers

None.

## Where to look

- `joharness.sh:protocol_paths` — the list every reader shares.

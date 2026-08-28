---
workstream: unsupervised-boundary-role
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: unsupervised-boundary-role
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-28
next: Implement the plan — protocol_trees() in joharness.sh first, then the guard, then the fixtures.
---

## Goal

Issue #114: the unsupervised boundary names one path prefix while protocol
text now lives in two trees. `.claude/agents/verifier.md` is mandatory Loop
step 5 protocol and sits outside `.agents/harness/`, so the guard that
detects a crossing does not see an edit to it.

## Decisions

- Shape chosen by the requester 2026-08-28, offered three ways: state the
  rule by ROLE and back it with a path check. Wording alone was declined as
  unenforceable; naming both trees alone as stale on the next move. This is a
  ratified-requirement edit, which is why it was asked rather than decided —
  the issue says so in its own last paragraph.
- `.agents/env/` stays out. A layer is sandbox configuration, not protocol
  text; it does not govern a session's behavior, and sweeping it in would
  stop the mode provisioning anything.
- `.agents/docs/` stays out too, and this one is a judgement call worth
  recording: those files are the reasoning BEHIND rules rather than the rules
  a session executes. Including them is defensible and has a wider blast
  radius, so it is a separate decision rather than a silent widening.
- Same-session plan: implementing here, so plan and workstream file retire in
  the same pull request as the code.

## Rejected

- Deriving the tree list from `sync-to-consumer.sh:DIRS`. Tempting — the ship
  boundary and the protocol boundary overlap heavily, and this session just
  built a classifier over exactly those lists. Rejected because they answer
  different questions: DIRS also ships `.agents/docs` and `.claude/skills`,
  which this plan deliberately leaves out. Reusing it would silently import a
  scope decision the requester has not made.

## Review

Not yet run: no edge, no pull request open.

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the boundary block; `grep -E
  '^\.agents/harness/'` is the entire mechanical boundary today.
- `joharness.sh:cmd_session_start` — the banner that states it to a session.
- `docs/product/unsupervised-mode.md` — Constraints, including the three the
  requester declined on 2026-08-24. Do not add those back.

---
workstream: guard-fires-on-an-empty-branch
status: review
branch: manage/guard-fires-on-an-empty-branch
pr: none
plan: guard-fires-on-an-empty-branch
issue: 296
session: https://claude.ai/code/session_01QFGN1dp5sjk2H9WFFaLyE4
agent: opus
updated: 2026-10-10
next: Retire workstream file, open PR, merge
---

## Goal

Settle `docs/research/guard-fires-on-an-empty-branch.md` (issue #296): the
handover guard's "branch has no upstream" fact fires on a branch with zero
commits and a clean tree. Graduate the answer into
`.agents/harness/handover-guard.sh` with selftest cases, delete the node.

## Decisions

- The guard fix itself already landed on main (2c300a0b, #296): count
  against `origin/<base>`, fire when the count is unreadable. This branch
  settles the two open decisions in writing and adds the missing case.
- Ref = `origin/<base>`: shared view; stale it is older than the fork point,
  so the count only grows — false fire, never a missed one.
- Unreadable base = FIRE. Not the header's "unexpected exits 0": that is the
  guard breaking, this is an ordinary git state, and silence drops the very
  commits the fact exists for.
- Selftest: new case deletes `refs/remotes/origin/main` on a branch with an
  unpushed commit and expects the fact; empty-branch case tightened from a
  one-phrase refute to whole silence.

## Rejected

- The issue's `|| echo 0` patch: fails open when `origin/<base>` is absent
  (measured in the research file).

## Review

- r1: (verifier) guard comment claimed a stale origin/<base> is "older than the fork point" and can "never" miss; a remote main rewound after fetch keeps HEAD locally, counts 0, misses (reproduced in its own fixture) (fixed: premise stated — ancestor of the real remote, fast-forward history — and the rewind case named)
- r2: (verifier) Where to look cited selftest :396, which is the cb0028e line; now 549 (fixed)
- r3: (verifier) selftest comment cited "(research, 2026-10-08)", a file this diff deletes (fixed: path + how to recover it from history)
- r4: (verifier) "the guard spoke on the released edit" already reds on `|| echo 0`, so the node's "nothing pins this" was untrue on main (fixed: new case's comment says it is not the only pin, only the named one)
- r5: author mutation runs 2026-10-10, scratch copies of this tree, `.agents/harness/selftest.sh`: `|| echo 0` guard → new case FAIL; pre-2c300a0b guard → empty-branch case FAIL; process pair + manifest walk fail in every scratch copy (artifact, pass on real tree: 2406 passed, 0 failed) (no change)

## Blockers

None.

## Where to look

- `.agents/harness/handover-guard.sh` — the `elif` under the upstream check.
- `.agents/harness/selftest/handover-guard.sh:549` — existing never-pushed case.

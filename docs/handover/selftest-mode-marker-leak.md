---
workstream: selftest-mode-marker-leak
status: review
branch: claude/selftest-mode-marker-leak
pr: none
plan: docs/plans/selftest-mode-marker-leak.md
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file and the plan, open the pull request, merge.
---

## Goal

Setting the session-local mode marker redded the suite for a reason unrelated
to anything the operator changed. This is the first plan this repo's own
source sweep generated (PR 163), now built.

## Decisions

- **Pin the file, do not clear it.** The fix is to point `JOHARNESS_MODE_FILE`
  at an absent scratch path in the cases that run the real entrypoint. The
  plan's own Trap forbids the alternative — a runner that cleared the marker
  would edit the operator's session state, and a test that changes the
  machine it runs on is worse than the flake it removes.
- **The marker's design is untouched.** Living inside the git directory is
  right: git tracks nothing there, so it cannot reach a commit and does not
  survive a clone. The defect was the fixture's isolation.
- **A static invariant case, not just the fixed assertion.** Every call to the
  real entrypoint in this topic must pin `JOHARNESS_MODE_FILE` or
  `JOHARNESS_MODE`, checked by scanning the topic file. The next case added
  here would otherwise inherit the same exposure silently.
- **The invariant case joins continuation lines first.** The call that started
  this was written across two lines with the env on the first, so a
  line-at-a-time scan would have called it unpinned and a naive fix would
  have pinned the wrong line.

## Rejected

- **Clearing the marker in the runner.** See above; the plan named it.
- **Loosening the invariant until it passed.** Its first run flagged two
  `cp "${ROOT}/joharness.sh"` lines, which copy the entrypoint and never run
  it. Excluded by what the line DOES, not by widening the test — widening it
  to swallow those would have left it pinning nothing.

## Verification

The plan's Acceptance is all three marker states, because a fixture that
hardcodes "no marker" passes one of them and fails the others:

```
mode unsupervised -> 1107 passed, 0 failed
mode supervised   -> 1107 passed, 0 failed
mode default      -> 1107 passed, 0 failed
```

Before the fix, `unsupervised` was 1105 passed, 1 failed.

`mutate` on the isolated call, reverting it to the un-isolated form:

- with the marker set → reds **2**: `supervised session-start says nothing
  about mode` and `every call here pins the mode source it is testing`
- with no marker → reds **1**: the invariant case alone

That second run is the one that matters. CI never has a marker, so a guard
that only fired under one would not guard CI at all.

`ci: pass`; `verify` 6 passed, 0 failed. Marker cleared, `mode` reads
supervised, tree clean.

## Review

Round 1, opus, self, with `mutate`.

- r1: the invariant case failed on its first run, flagging two `cp` lines.
  The tempting repair was to widen the pattern until it went quiet, which
  would have produced a check that passes over everything. (fixed — excluded
  `cp` by what it does, and the reasoning is in the awk beside it)
- r2: I nearly pinned only the one case that had failed. Three more calls in
  the topic read the default marker — including one whose `JOHARNESS_MODE=''`
  is unset to the shell, so the marker would decide it. The failing case was
  the one whose assertion happened to be sensitive, not the only exposure.
  (fixed — all of them, and the invariant case is what keeps it true)
- r3: the mutation had to be run twice, with and without a marker, or the
  guard's value would have been assumed rather than measured. Without that
  second run I would have reported a case that guards nothing on CI.
  (fixed — both runs recorded above)
- r4: verifier round owed and NOT run — standing instruction, twenty-second
  consecutive edge. (wontfix on this branch — this session cannot spawn
  subagents; the gap is the human's to lift and is reported on every edge
  until it is)

## Blockers

None.

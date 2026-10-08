---
workstream: unowned-block-age
status: in-progress
branch: claude/unowned-block-age
pr: none
plan: unowned-block-age
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: sonnet
updated: 2026-10-08
next: Verifier pass at opus over the branch diff, record findings, then retire this file and the plan and open the pull request.
---

## Goal

Issue #254, third proposal reduced: a parked branch's dispatch row reads the
same at ten minutes and six days. Print how long the BLOCK has stood (the
commit that last set the parked status in this workstream file on this ref),
not the push age. Supervised-only plan (scope holds `joharness.sh`), taken
in a supervised session at the human's request, 2026-10-08.

## Decisions

- ONE git call per parked row: `git log --first-parent -m -p --unified=0
  -G'^status:...blocked' <ref> -- <file>`, newest first, and the first
  commit whose diff ADDS the whole frontmatter line is the answer. The file
  is parked now (the caller checked), so a later unpark-and-repark would be
  a newer add — the first add met is the current block. No per-candidate
  `git show`, which the plan's content walk would need and its
  one-call-per-row acceptance forbids.
- A matched commit with NO parents is a shallow boundary, and reads as
  unknown. `-p` shows a parentless commit as adding every line, so the
  boundary would otherwise "park" at the push's date — the confidently wrong
  duration the plan warns against. A workstream file is never born in a
  repository's true root commit. `%P` rides on the same format line.
- The existing row text `BLOCKED: the human's, holds no slot` is kept
  verbatim — two topics and the forge case match it — and the age is
  appended: `, parked <age> ago`.
- The cases have their OWN fixture at the end of the topic, so the branches
  and plans they add move no count the shared fixture's later cases assert.

## Rejected

- `-S` read at either end: the plan's trap. Its oldest match is the first
  block (mutation "oldest" reds 2 cases).
- A content walk with one `git show` per candidate: right, and costs a git
  call per candidate, against the one-per-row acceptance.

## Review

- r1: (session) the plan's "newest `-S` match may be an unpark" cannot
  happen while the file is parked — the newest status change is then the
  current park. The defect the fixture separates is the OLDEST end. A
  mutation built on the newest end ("first change of either sign") stayed
  green for that reason, and was replaced. (no change — the plan's own
  Acceptance case is right; one sentence of its reasoning is not)
- r2: (session) first shallow case passed over nothing: the bare origin's
  HEAD names a branch it never had, so the clone checked out no files, ran
  no dispatch, and the refute read an empty string. (fixed — `-b main`, and
  a positive assertion that the shallow run listed the row)
- r3: (session) shellcheck SC2030/SC2031 on a subshell `export` of the
  commit dates. (fixed — prefixes on the one git command, the stall cases'
  idiom)
- r4: (session) proved by injecting each defect into a COPY (scratch
  worktrees, never this tree), full selftest each, 2026-10-08: push age as
  block age reds 6; oldest park reds 2; no shallow check reds 2; annotation
  removed reds 2 positive assertions; the prose-quoting case reds 3 only
  with BOTH anchors removed — `-G '^status'` and the exact-line awk match
  are redundant guards, each covering the other. Baseline 2286/0. (fixed)

## Blockers

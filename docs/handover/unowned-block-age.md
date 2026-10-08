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
next: Retired with the plan in the last commit before the pull request; merge when checks are green.
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
- r5: (verifier) the age read off the wrong commit, too young and
  confident, in five histories, each run: a rebase (`%ct` rewritten; 200h
  read 5h); a rename (the new path's first commit creates every line; 200h
  read 10h); a whitespace edit of the parked line (`status:blocked`; 10h); a
  bare `status: blocked` line pasted into the body (10h); a park on a side
  branch merged in (50h — dated by the merge). (fixed — a park is now a VALUE
  TRANSITION: the added status value is blocked and the removed one is
  something else, or the file is created; `%at`; `--follow`. The side-branch
  case keeps the merge's date by design: it is when the park reached this
  branch. All five rerun with the verifier's own scripts: 200h, 200h, 200h,
  200h, 50h.)
- r6: (/code-review) `status: blocked  # why` — the frontmatter reader
  strips the comment and calls the row blocked, but the age query required
  a bare line, so the row read unknown forever and blamed a shallow clone.
  (fixed — the value is read before any `#`; case "noted")
- r7: (/code-review) the unknown text named a shallow clone as THE cause;
  other causes existed (r6). (fixed — it now says the parking commit is not
  in this clone's history, which is what was measured)
- r8: (/code-review) the existing refute `holds no slot  holds ` went
  vacuous once the age was appended between the two. (fixed — keyed on the
  `mgr-beta` row and the hold annotation's own words)
- r9: (/code-review) the walk had no lower bound past the answer. (fixed —
  `<merge base>..<ref>`, the base the row already computes)
- r10: (verifier) no positive shallow case: a regression that always printed
  unknown on a shallow clone would pass. (fixed — depth 3 holds the park and
  must read 200h)
- r11: (/code-review) other views (`analysis`, status) still show no age.
  (wontfix — out of this plan's scope, `dispatch` only; a follow-up plan if
  wanted)
- r12: (verifier) clock skew gives a negative age. (wontfix — same as the
  push-age reader beside it; changing one alone would make them disagree)
- r13: (session) the five new history cases red against the first build's
  `joharness.sh` (696ad3f) in a scratch worktree: 2286 passed, 6 failed,
  each a named history. `ci: pass`, 2292 passed, 0 failed. (fixed)
- r14: (verifier, round 2 at 319224b) a body line that already held a
  status, rewritten to blocked ("status: draft" to "status: blocked") on a
  file already parked, read as a new park: 5h for a 300h block. The awk took
  the first `+status:`/`-status:` line anywhere in the diff. (fixed — full
  context, `-U99999`, and only lines between the opening and closing `---`
  count, on each side of the diff separately: the span gr_fields reads.
  Case "prose"; the previous build reds it.)
- r15: (verifier, round 2) four paths no case pinned: the creation rule, the
  walk's last-commit judgement, `-m`, and the `<base>..` range. (fixed for
  the first two — case "born", a file created parked as the oldest commit in
  range; each mutation reds it. `-m`: a merge fixture now exists ("merged",
  dated by the merge), but dropping `-m` stays green because current git
  already shows a first-parent diff for merges under `--first-parent`; kept
  for older git, unpinnable here. The range changes cost only, never the
  answer, newest-first. Both recorded, not forced.)
- r16: (verifier, round 2) the helper stripped a comment after `[[:space:]]*#`,
  `gr_fields` after `[[:space:]]+#`: `status: blocked#why` read blocked by one
  and `blocked#why` by the other. (fixed — the same pattern; two readers of
  one field must agree)
- r17: (session) `ci: pass`, 2295 passed, 0 failed. Previous build reds 1
  (prose); no-creation and no-final-judgement mutants red 1 each (born);
  no `-m` stays green as r15 says. All in scratch worktrees. (fixed)

## Blockers

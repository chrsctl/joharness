---
workstream: harness-rules-field-review
status: in-progress
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: harness-rules-field-review
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Adversarial review, then finish
---

## Goal

Plan `docs/plans/harness-rules-field-review.md`: a measured field review of
consumer `chrsctl/redocted` found four defects in the CURRENT canonical rules
(every harness file there byte-identical to this repo's). Fix the rule text.

## Decisions

- Edit 1's premise VERIFIED here before writing, against this session's own
  merged work rather than the plan's word: `git show <merge>:docs/handover/
  smoke-helm-coverage.md` returns `fatal: path ... does not exist`, and
  `git log -- <path>` from main returns empty (history simplification prunes
  a file that lived and died on a side branch). The two-step the plan
  proposes does work: `git log --all --full-history` finds the retire commit,
  `git show <commit>^:<path>` prints the file, all 8 review findings intact.
  This session alone has retired 7 such files, every one currently
  unreachable by the documented command.
- `.agents/harness/AGENTS.md` measured at the commit this starts from:
  10,280 bytes, 168 lines. The plan's own figures (5,617 / 6,500 / 8,636)
  were already stale, as it predicted. Budget: +10 lines, checked at the end.
- Edit 3 (a test must fail without its fix) is the rule this session kept
  needing: PR 91's helm check and PR 94's rename fixture both had to be
  proven able to fail, and PR 94's fixture DID pass vacuously until an
  assertion caught it. Written from that experience, not from theory.

## Rejected

- Writing edit 2 narrowly (runners only). `fork-seam-rules` shares both scope
  files and carries a near-twin re-derive rule for fork state; the plan says
  whichever lands second must point at ONE generic sentence rather than add
  the twin. Mine is written generically ("infrastructure reading ... re-derived
  at every check") so that plan can point at it instead of restating it.
- Putting the recovery command only in the handover README. Step 7 carries the
  pointer too, because the session that needs the record is reading a merged
  PR, not the protocol doc.

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/docs/handover/README.md:68` — the `Survives PR` bullet's broken
  retrieval sentence.
- `.agents/harness/AGENTS.md:73` — step 5's never-skip line, edit 3's neighbour.
- `.agents/harness/AGENTS.md:81` — step 7's `Merge when ALL hold`, edit 2's home.
- `AGENTS.md:49` and `.agents/docs/feedback.md:8` — where "trust counted
  numbers" already lives, edit 4's anchor.

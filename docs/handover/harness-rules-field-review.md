---
workstream: harness-rules-field-review
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: harness-rules-field-review
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: Fold in doctrine lens findings, then merge
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

Opus tier = adversarial, separate lenses. Does-it-reproduce done 2026-08-28;
doctrine still running, its findings land before merge. Nothing in the diff
was refuted; the reason-level error below was.

- r4: MY REASONING WAS WRONG, in the commit that adds the rule against
  exactly this. I wrote that `--all` needs the branch ref alive and that this
  is why `--full-history` matters. Measured: `--full-history` alone, with no
  `--all`, finds all six retired files; `--all` alone finds none. Reachability
  comes from the merge commit's SECOND PARENT, not the branch ref. Right
  conclusion, wrong mechanism — a claim that reads as evidence and is not.
  (fixed: the text states the measured mechanism and what `--all` actually
  covers. Re-verified by me, not taken from the lens: plain log 0, `--all` 0,
  `--full-history` 4 and 5)
- r5: "File merges with code, then is deleted before the merge" contradicted
  itself — the old sentence survived an edit that made it false. What merges
  is the DELETION. (fixed)
- r6: step 2 was under-specified: `<retire-commit>` was never tied to step
  1's output (it is the newest entry), and `^` is first-parent, which is safe
  only because every retire commit so far is single-parent. (fixed: both said
  out loud)
- r1: (reproduce) the broken command reproduced 6 of 6, and STRONGER than
  claimed: the file is absent from every commit on main's first-parent chain,
  not merely from the merge commit — the retire commits are single-parent and
  sit on the side branch.
- r2: (reproduce) both halves of the simplification claim, 6 of 6: plain
  `git log` on main returns 0, `--all --full-history` returns 3 to 5.
- r3: (reproduce) the fixed command recovers real records: 14 findings from
  ci-scope-selftest, 12 from smoke-rerun-safety, plus verify-in-ci 17,
  smoke-helm-coverage 8, k8s-136-validation 1, backpass-compat 4. Fifty-six
  findings that were unreachable by the documented command this morning.
- r7: (reproduce) growth exactly +10 lines, +694 bytes — at the plan's
  budget, not over. Measured against origin/main, not written from memory.
- r8: (reproduce) `ci` pass with the selftest RUNNING, not skipped: yesterday's
  new gate correctly treats `.agents/docs/...` as non-inert, since it is not
  `docs/*`. `verify` 8/8.
- r9: (reproduce) step 7's new "PR body carries the recovery command" rule is
  unexercised by its own change. (self-applied: this branch's PR body carries
  the command for this workstream file)
- r10: (reproduce, not a defect) the pruning is a property of the
  delete-before-merge shape rather than of retired files in general — a file
  retired some other way still shows in a plain log. The text describes the
  case it names.

## Blockers

None.

## Where to look

- `.agents/docs/handover/README.md:68` — the `Survives PR` bullet's broken
  retrieval sentence.
- `.agents/harness/AGENTS.md:73` — step 5's never-skip line, edit 3's neighbour.
- `.agents/harness/AGENTS.md:81` — step 7's `Merge when ALL hold`, edit 2's home.
- `AGENTS.md:49` and `.agents/docs/feedback.md:8` — where "trust counted
  numbers" already lives, edit 4's anchor.

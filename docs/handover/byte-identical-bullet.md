---
workstream: byte-identical-bullet
status: blocked
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-03
next: HUMAN — the requirement's second bullet is false and has been since before PR 202. Fixing it rewrites the requester's words. Decide; a session should not.
---

## Goal

Continuing the Loop after PR 202, then answering "do we still need
docs/product markdown". The branch tried to fix a `Satisfied when` bullet
it believed PR 202 had falsified. **The content is reverted and this file
is the whole deliverable.** The verifier round below is why.

## Decisions

- **ABANDONED, not patched.** The bullet fix was wrong at its premise, its
  remedy and its evidence, each independently. Patching it would have kept
  a change whose reason for existing does not hold.
- **`docs/product/` stays.** Nine requirements have existed on `main`;
  eight were satisfied and deleted by their last plan's pull request
  (`git log --all --diff-filter=A/--diff-filter=D --name-only -- 'docs/product/*.md'`,
  2026-09-03). That is a working lifecycle, not a vestige. It is also the
  only human input the queue can compute on — no hook can read GitHub — and
  `bootstrap-consumer.sh` tells every new consumer the queue starts there.
- **The requirement is NOT retired.** Bullet 6 reads NOT shown, and
  `.agents/docs/product/README.md` says satisfied is what the last plan's
  pull request deletes. Deleting it would claim a satisfaction that has not
  happened.
- **Its text is not a session's to rewrite.** `.agents/docs/product/README.md`
  calls a requirement's body the requester's words;
  `.agents/harness/AGENTS.md` step 2 says nothing builds unplanned. This
  branch did both — `plan: none`, editing `docs/product/` and protocol
  text. `lint_requirement_writes` counts ADDED files only, so nothing
  mechanical stopped it. The human is the only check, which is why this
  file stops here instead of merging.
- Verified with zero requirements in the tree (scratch worktree,
  2026-09-03): `ci` passes and the queue reports cleanly, so retiring is
  mechanically safe whenever the human judges it right. That is a fact
  about the code, not permission.

## Rejected

- Rewriting the bullet to match the code. That is weakening a requirement
  to fit an implementation, and r1 shows the rewrite forbade nothing at all.
- Fixing the CODE so the old bullet becomes true — making `ci`'s
  requirement-authorship stage silent under supervised. Defensible, and a
  real option for the human, but it changes what every supervised session
  sees to satisfy a bullet nobody has confirmed they still want as written.
- Retiring the requirement to clear the queue. See Decisions.

## Review

Round 1, verifier at opus, 13 findings. The first four end the branch.

- r1: (verifier) the rewrite is a WIDENING that forbids nothing.
  `run_mode()` normalises every non-`unsupervised` value to `supervised`
  and the hook reads `${JOHARNESS_RUN_MODE:-supervised}`, so "supervised
  sees what the same tree shows with the mode unset" is true by
  construction at every branch in the codebase. The old wording forbade
  something real. (fixed by reverting)
- r2: (verifier) the premise misattributes. The bullet was ALREADY false at
  `568a0b9`, before PR 202, at a site PR 202 never touched: `ci`'s
  `== requirement authorship` stage prints two supervised-only lines that
  exist solely because the mode exists. Re-verified here in worktrees at
  `568a0b9` and at `main` — identical text on both. The commit subject
  "PR 202 falsified" names the wrong cause. (fixed by reverting)
- r3: (verifier) "PR 202 did it three times" is a measured undercount:
  20 hunks, 141 changed lines between the two trees, including shellcheck
  61→60 files, eol 96→95, the pass count, perf numbers, ~120 reworded PASS
  lines, and the `sources` SUBCOMMAND a supervised session could run. A
  number presented as measured, inside a requirement, that a re-count
  contradicts. (fixed by reverting)
- r4: (verifier) "compares all three on every fixture it builds" is false.
  `eq_same` is called 5 times over 6 fixture states, and the sixth asserts
  the modes DIFFER (`queue-context-edge.sh:138`). Re-counted here: 5 calls,
  and line 138 is the refute. The cited pin has a counterexample in its own
  file. (fixed by reverting)
- r5: (verifier) uncorrected copies of the claim remain, including the Goal
  six lines above the edited bullet — "supervised stays the default and
  stays exactly as it is", the across-trees promise the rewrite declared
  impossible — plus `queue-context-supervised-only.sh:79-80` and
  `queue-context-edge.sh:137`. Two of them say "Acceptance" where a
  requirement has `Satisfied when`. (open — real, and left for whoever
  fixes the bullet; correcting comments around a claim nobody has settled
  would be the same mistake one layer down)
- r6: (verifier) the workstream rejected "recording dated annotations in
  the requirement" and then wrote a dated three-item changelog into it.
  (fixed by reverting)
- r7: (verifier) "seven of eight bullets read true, each pinned" — bullets
  4 and 5 are field observations of live runs that no selftest pins and
  none could, and by this branch's own claim that bullet 2 was false the
  count was six, not seven. (fixed: the count is not restated here; what is
  pinned and what was observed are different things and this file no longer
  conflates them)
- r8: (verifier) unplanned build. Step 2 admits one carve-out and this is
  not it. (fixed by reverting; recorded in Decisions as the reason the
  branch stops)
- r9: (verifier) no review record existed and `JOHARNESS_REVIEW=off` means
  `ci` would never have caught that; step 4's `feedback <path>` was not run
  either, and it would have surfaced PR202 r13 already counting TWO
  supervised changes. (fixed: this section; the feedback read is moot now
  that the diff is empty)
- r10: (verifier) "#165 now carries the second half" is a claim about
  external state with no artifact in the tree, unverifiable from the
  container. (no change needed — the comment exists at
  github.com/chrsctl/joharness/issues/165, posted this session; the
  verifier correctly could not confirm it and correctly said so)
- r11: (verifier) "drain's second line under DRAINED" is the third line of
  the block. (fixed by reverting)
- r12: (verifier) "`ci` lost its sources selftest topic" understates it —
  the SUBCOMMAND went, the topic followed. (fixed by reverting)
- r13: (verifier) `finish` is red on the workstream file, expected
  mid-build. (no change needed — this branch opens no pull request)

## Blockers

The human's, and only theirs: the second `Satisfied when` bullet of
`docs/product/unsupervised-mode.md` is false, at `== requirement
authorship` and at `authority`, and was before PR 202. Three ways out —
reword the bullet, silence those stages under supervised, or accept the
exception in writing. All three are the requester's words or a change to
what every supervised session sees.

## Where to look

- `docs/product/unsupervised-mode.md` — the second bullet, and the Goal's
  "stays exactly as it is" six lines above it.
- `joharness.sh:lint_requirement_writes` — the supervised branch that
  prints mode-only text into every `ci` run.
- `.agents/harness/selftest/queue-context-edge.sh:eq_same` — 5 calls, 6
  fixtures, and line 138 where the modes are asserted to differ.

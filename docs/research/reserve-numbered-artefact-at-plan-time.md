---
research: reserve-numbered-artefact-at-plan-time
urgency: normal
agent: opus
effort: medium
graduates: .agents/docs/consumer-repos.md
---

<!--
A report from a consumer (chrsctl/gx). Everything under "The consumer's
evidence" is the consumer's reading, restated; this file's author could not
re-measure it from the canonical checkout.
-->

## Question

Should the harness tell a plan writer to reserve a numbered artefact in the consumer's registry when the plan is written, and should the finish loop's retest set treat the rename of a file the branch already changed as a RETEST rather than a full run?

## Echo

A branch that adds a file with a sequential number (a decision record, a criterion id) loses the number to whichever branch merges first. The branch renames its file, and the finish loop then sees a path neither side changed and pays a full run. The two halves: (a) nothing in plan writing prevents the clash; (b) the finish loop prices each clash at a full run. What rests on the answer: whether a consumer that numbers artefacts can reach a merge before the base outruns it.

## Sweep

`goal-directed`: only the rule's key terms over canonical's own files, plus the one finish-loop step the consumer's measurement names.

## What would settle it

Either way: (a) canonical already states a reserve-at-plan-time step (a hit on the terms below), or the plan and clerk procedures state none; (b) the finish-loop step 3 text counts a rename of a branch-changed path as in `conflicted ∪ branch ∪ base`, or it does not.

## Method

Run from this checkout at `origin/main`:

```
git grep -n -i -E 'reserve|reservation|renumber|rename|neither side' origin/main -- AGENTS.md .agents .claude
git grep -n -i -E 'numbered|next number|registry' origin/main -- .claude/commands/plan.md .claude/commands/clerk.md .agents/docs/plans.md
```

then read `.agents/docs/consumer-repos.md` "The finish loop" step 3 and the paragraph before it, `.agents/docs/plans.md` around line 103, `.agents/docs/product.md` around line 64.

## Findings

- **Canonical carries no reserve-at-plan-time rule.** The first grep hit nothing on `reserve`/`reservation` in a plan or clerk procedure. Its only `reserve` hit is `consumer-repos.md:316`, "Why not a reserved exit code", unrelated. `renumber` hits: `consumer-repos.md:234` (ids after a merge, RETEST), `product.md:64` ("Numbers are positions", clause numbers inside a requirement), `checks.sh:1066,1147,1155` (selftest fixture for a renumber). None tells a plan writer to claim a number before the build. The second grep: `plans.md:103,106` mention a "registry" only as a file two plans may both touch (overlap marking, `shared:`), which is a different problem; `.claude/commands/plan.md` and `clerk.md` hit nothing on `numbered`, `next number` or `registry`.
- **Finish loop step 3 reads a renamed branch file as outside all three sets (consumer's reading, from the text).** Step 3 (`consumer-repos.md`, "The finish loop"): "A resolved path outside `conflicted ∪ branch ∪ base` = full run". `branch` = paths changed in `mb..H0`. A file the branch adds at `H0` under number N and renames after the merge to N+k is a path at N+k that is in none of the three sets, so the text sends it to the full run; the old path N is in `branch` but is deleted, not retested. `consumer-repos.md:234` says "Renumbering ids after a merge lands in `RETEST`" and names only edits inside the sets; a renumber that renames a file is not that. This file's author read the text; they did not run a rename through `finish`.

### The consumer's evidence (restated, consumer's reading, not re-measured here)

- Rule adopted by chrsctl/gx, its ADR 0413 (chrsctl/gx PR #1575, merge c0dca5767): a plan that will add a numbered artefact reserves the number in a registry file on the base branch, in the plan's own pull request; the building branch uses only that number and never renames the file. The same was done for criterion ids a day earlier (its ADR 0383).
- Measurement behind it: gx manager session `session_01J1YMK7L9P1a1Heoa2ULivh` (chrsctl/gx PR #1557, merged 4a7ea1d1b) renamed its decision-record file six times (0390 to 0396), because the base merged another branch holding the same number each time. Under `JOHARNESS_CHECKS=local`, `finish` printed: `full run     certified 030621d48 found, no catch-up: HEAD changed docs/adr/0396-the-inbox-strip-is-open-waits-on-you-returned.md, which neither side nor the merge did: something else changed`.
- Cost, as the consumer reported it: each rename cost a full run of about 24 minutes instead of a catch-up; the base outran 9 green finish runs (behind 26, 27, 19 · 3, 12, 17 · 20, 13, 7, from the manager's own comment on #1557); both STARVED resumes were spent and a human was asked.

### Not verifiable from here

- The numbers above, the session, and the run output (gx's private history; this checkout has none of it).
- Whether a rename's destination path really lands outside the sets under `git merge-tree`/`git diff` rename detection in `finish`'s code: no experiment was run. `--no-renames` use elsewhere in the harness (`queue-context.sh:423`) suggests rename handling is per-command; the finish-loop code was not read.
- Whether a RETEST of a renamed file is safe: the consumer's own checks are what a retest re-runs, and a renumber can change cross-references in files neither side touched.

## Consequence for the queue

Two harness files change, if canonical agrees:

- (a) `.claude/commands/plan.md` and `.claude/commands/clerk.md`, with the rule's home in `.agents/docs/plans.md`: a plan that will add a numbered artefact reserves the number in the consumer's registry in the plan's own pull request, and the building branch uses only that number. Stated without the consumer's layout: "registry" is whatever file the consumer names for it.
- (b) `.agents/docs/consumer-repos.md` § Local checks, "The finish loop" step 3: decide whether a rename of a path the branch already changed is a RETEST (add the destination to `R`) or stays a full run, and then make line 234's sentence say which.

Or none, if canonical judges (a) a consumer practice that needs no harness step and (b) a deliberate bound.

## Verification

Not yet verified from a second context. The two greps and the step 3 / line 234 reads above were run by the author of this file, from this checkout at `origin/main`: GROUNDED for "no reserve-at-plan-time rule in canonical" and for the quoted step 3 text; WEAK for the claim about what `finish` does with a rename (text read, not run); UNGROUNDED here for all gx figures (consumer's reading).

## Graduates to

`.agents/docs/consumer-repos.md`: half (b) lands in its finish loop, and half (a) cites it from `plans.md`.

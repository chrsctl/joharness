---
workstream: selftest-split
status: done
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: selftest-split
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Merge the pull request once checks are green.
---

## Goal

The queue serializes on one file. Split the selftest's topics into files a
plan can scope by name, so plans that touch different topics stop blocking
each other. A move, not a rewrite: same assertions, same order, same count.

## Decisions

- **The plan's premise numbers are stale, and the case got stronger, not
  weaker.** Recounted on `cf38699`, 2026-08-29: 3 of 5 scope-declaring plans
  name `selftest.sh` (the plan says 13 of 20 — five plans merged this
  session), but the file is **6,266 lines and 40 topics** against the plan's
  3,423 and 27. This session alone added ~450 lines to it across three
  plans. The payoff today is NOT two plans moving into wave 1 — I wrote that
  here first and it is wrong; the acceptance section below is where it is
  corrected.
- **The in-flight trap applies squarely, and my first reading of it was
  wrong.** `origin/claude/backpass-usage-review-sbew6t` carries a plan whose
  own `scope:` names `.agents/harness/selftest.sh` — exactly the branch the
  trap means. I first wrote that its plan "is already retired from `main`".
  False: that branch ADDS `docs/plans/unsupervised-boundary.md` (77 lines)
  and its workstream file. It is live unmerged work carrying its own plan.

  Proceeding anyway, on the measured cost rather than that mistake. The trap
  states its own reason — "or the merge conflicts are the whole diff" — and
  they are not. `git diff --numstat` against its merge base, 2026-08-29:
  **26 insertions and 4 deletions in 3 hunks** (I first wrote 4 hunks and
  omitted the deletions). Each hunk maps to one topic file, computed rather
  than guessed:

  ```
  their line 2838  ->  .agents/harness/selftest/autonomy-mode.sh
  their line 3206  ->  .agents/harness/selftest/handover-guard.sh
  their line 3241  ->  .agents/harness/selftest/handover-guard.sh
  ```

  The pull request carries that table, so that session re-applies 30 lines
  into two named files rather than resolving a 6,000-line move.
- **Topics 1-3 stay in the runner, and that is the layer rule's doing, not
  laziness.** `grep -w k8s` finds 8 lines: two in the preamble (the
  carve-out constant and the comment explaining it) and six in the k8s topic.
  The rule permits exactly ONE file under `.agents/harness/` to name a layer,
  and a second carve-out is "a red run, not a judgement call" (AGENTS.md Part
  2). Splitting them puts the layer's name in two files. So the file that
  enforces the rule and the file that benefits from it stay the same file —
  `selftest.sh` — and topic 2 sits between them, where moving it alone would
  mean interleaving a `source` between two inline topics for nothing.

## Decisions (continued)

- **Two plan claims turned out to be hypotheses, and both were wrong.**
  (1) "add `.agents/harness/selftest` to `CANONICAL_ONLY_DIRS`" is not
  sufficient: that array was read only by the report telling a consumer what
  it already carries. `.agents/scripts` stays out of consumers by being
  absent from `DIRS` entirely — but `.agents/harness/selftest/` sits INSIDE a
  synced tree, so the list alone would have shipped all 37 topic files while
  exempting the runner that sources them. `canonical_only()` now matches
  directory prefixes too. (2) "the shellcheck wiring: new topic files are
  linted with zero changes" — they are linted, and they were not clean: 15
  SC2154 and 3 SC2034, because shellcheck lints each fragment alone and every
  shared fixture is assigned in another file.
- **The SC2154 silences are per file and carry the reason.** Not repo-wide:
  the cost is a typo'd variable going unflagged in that one file, and it is
  accepted where the alternative is dropping the check everywhere.

## Rejected

- **A glob instead of an ordered list.** The order IS behaviour — topics
  build fixtures later topics read — and a glob makes it a property of
  filenames. The list is explicit and two fatal checks keep it honest.
- **Counting the integrity checks as assertions.** They print and `exit 1`
  instead. The plan requires the total to be unchanged, and a dropped source
  counted as one failure among 820 is exactly how it would be missed.

## Acceptance: one item is NOT met, and the reason is the plan's own trigger

"Two queued plans that both name `selftest.sh` re-declare their scopes to
disjoint topic files and land in the same wave." They re-declared —
`cleanup-audit` to `selftest/cleanup.sh`, `finding-id-lint` to
`selftest/review.sh` — and they still do not share a wave, because both also
scope `joharness.sh` and always did.

What the split actually bought, from the hook's own output:

```
before   wave 2: moment-feedback-hooks — overlaps selftest-split on .agents/harness
         wave 3: cleanup-audit — overlaps selftest-split on .agents/harness/selftest.sh
         wave 4: finding-id-lint — overlaps selftest-split on .agents/harness/selftest.sh
after    wave 2: cleanup-audit — overlaps moment-feedback-hooks on joharness.sh
         wave 3: finding-id-lint — overlaps moment-feedback-hooks on joharness.sh
```

**No wave line names `.agents/harness/selftest.sh` any more.** The serializer
moved rather than disappeared, which is the honest result and not the one the
acceptance is worded for. Marking `joharness.sh` `shared:` in both plans would
have produced the sentence the acceptance asks for; it would also be a claim
about parallel safety for work I am not doing, made to satisfy my own
acceptance criterion. Not done.

The plan's Out of scope says of splitting `joharness.sh`: "no queued plan is
blocked on it alone — do it when one is." Three now are. That is the
follow-up this plan earned, and it belongs in a plan of its own.

## A perf regression the split exposed, and did not cause

`ci` went red on the `review` row: **278 against a 265 ceiling**, counted
2026-08-29. `review_prior` forks an `awk` per file in the branch's diff, and
every branch measured until now changed a handful of files; this one changes
42. The loop did not grow a fork — the diff grew items — and the budget was
right either way.

Fixed at the loop, not at the literal: one awk over both lists instead of one
per file. **237 against 265** now, and the printed output is unchanged. The
doctrine's own words are why: "Find the loop that grew a fork; do not raise
the number to match the code."

## Review

Round 1, this session, while building.

- r1: the split found a live landmine on its first run — `jr()` defined in two
  topics with DIFFERENT bodies (`GITHUB_ACTIONS=''` in `review`,
  `HANDOVER_BASE_BRANCH=main` in `feedback-recurrence`). Safe today only
  because file order put each topic's uses before the other's redefinition.
  (fixed: renamed `recur_jr`, reason in place)
- r2: the plan's `CANONICAL_ONLY_DIRS` one-liner was not sufficient — that
  array was read only by the consumer report. (fixed: `canonical_only()`
  matches directory prefixes)
- r3: the plan's "linted with zero changes" was wrong — 15 SC2154, 3 SC2034.
  (fixed: per-file directives carrying the reason and the cost)
- r4: the 42-file diff put the `review` perf row 13 over its ceiling, which
  exposed a per-file `awk` fork inside `review_prior`. (fixed at the loop:
  278 -> 237, output unchanged)

Round 2, `.claude/agents/verifier.md` at opus. It reconstructed the original
from the runner plus the topic files in list order and diffed it against
`origin/main`: **verbatim confirmed, order confirmed.** Then 12 findings, 9
verified by execution. Six were real defects.

- r5: **both fatal checks were defeated by one name listed twice.** `sort |
  uniq -u` prints names occurring exactly once, so a name listed twice
  cancels itself out of the comparison: listed twice with a file present
  sources that topic twice and reads as agreement; listed twice with NO file
  reads as agreement while the topic never runs — the plan's own Trap,
  surviving inside the check written for it. `set -uo pipefail` has no `-e`,
  so the missing `source` prints to stderr and the suite exits 0. (fixed:
  duplicates in the list are their own check; all three cases abort, proven
  by running each)
- r6: **the duplicate-function check never compared topics to the RUNNER.** A
  topic redefining `commit_all` (75 call sites) or `pass` would shadow it for
  every topic sourced after, invisibly. (fixed: the runner is in the
  comparison, and three definition forms are matched instead of one)
- r7: **the consumer-leak guard the whole split depends on had no test.** My
  evidence was one manual `--dry-run` — a number nobody can re-count.
  Deleting both the array entry and the new loop left the suite at 820.
  (fixed: the sync fixture carries a topic file, and three assertions cover
  the directory rule, the runner's exact-path rule and the plan output)
- r8: **28 of 37 topics had their section header stranded in the previous
  file.** Cutting at the `step` line left each topic's rationale — counted
  measurements, "this block stays BEFORE" notes — with its predecessor, so a
  session scoping one topic by name got a generic header and none of the
  reasoning. That is most of what the split was for. (fixed: the boundary is
  the last `# --- ` section above the step)
- r9: found while fixing r8 — `# --- handover hook: a second remote ---` sits
  **95 lines and two topics above the code it describes**, appears once, and
  its topic has no header of its own. Pre-existing; the split would have
  frozen it into the wrong file. (fixed: moved to its topic. The one content
  change in an otherwise verbatim diff; it alters no assertion and no count,
  and the file says so at the seam)
- r10: `find` read the working tree, so an untracked stray `.sh` would red
  `ci` for a file git does not track — which the sync engine three files over
  already refuses. (fixed: `git ls-files`, falling back to the walk where
  there is no git)
- r11: the false claim about the in-flight branch's plan, and the miscounted
  hunks. (fixed in Decisions, with the recount and the hunk map)
- r12: this file said two plans move into wave 1 while the acceptance section
  below said they do not. (fixed)
- r13: `cleanup-audit` and `finding-id-lint` had re-declared `scope:`
  frontmatter but their Scope PROSE still named `selftest.sh` — a literal
  reader would put its tests straight back into the file this diff emptied.
  (fixed in both)
- r14: my comment claimed "the two checks below make the list impossible to
  get quietly wrong", falsified by r5 on the first try. (fixed: it says what
  the checks do, not what they guarantee)
- r15 (open, recorded): three topics assign `rwork` to three different
  scratch repos, `rorigin` likewise, `nogit` twice — the same "safe only by
  position" hazard as `jr`, and the new check is blind to the variable half.
  Each assigns at its own top before use, so any order is safe today.
  Extending the check is a bigger question than this plan: a topic
  legitimately READS another's fixture (`$work`, `$swork`, `$cwork`,
  `$syncsrc`), so it would have to tell reads from redefinitions.
- r16 (open, recorded): the duplicate-name grep can false-fail on a
  column-zero `foo()` inside a heredoc writing a fixture script. No topic
  does that today (55 matches, 0 heredoc hits). A real parser costs more than
  this is worth, and the failure would be loud.

Counts, both pasted as the plan asks: **820 passed, 0 failed** before the
split and at the split commit `2c60e7f` — the move added and dropped
nothing. **823** at the head, and the 3 are r7's new assertions for a guard
that had none, in a later commit.

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh:LAYER_CARVE_OUT_FILE` — why topics 1-3 stay.
- `.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS` — the one line
  that stops every topic file shipping to every consumer.
- `joharness.sh:cmd_ci` — the literal path the runner must keep satisfying.

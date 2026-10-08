---
workstream: where-a-consumers-own-findings-go
status: in-progress
branch: claude/where-a-consumers-own-findings-go
pr: none
plan: where-a-consumers-own-findings-go
issue: none
session: https://claude.ai/code/session_0128i4WUdEgZ88ygzuHHtXEK
agent: opus
updated: 2026-10-08
next: Re-run ci green, then retire this workstream file in the last commit before the pull request (the plan file is the deliverable and stays)
---

## Goal

Settle `docs/research/where-a-consumers-own-findings-go.md`: where a finding a
consumer discovered about its OWN product goes, given `upstream` refuses to
carry it to the canonical and `feedback` serves it only to a session touching
the same path. Graduate the answer into `.agents/docs/feedback.md` and delete
the research file.

## Decisions

- **Counted, not reasoned, and not on the canonical code path.** `cmd_upstream`
  returns early on `JOHARNESS_CANONICAL=1`, so the sweep ran with that one line
  stripped from a scratch conf (`JOHARNESS_CONF=<scratch>/consumer.conf`), over
  all 272 merged edges of `origin/main`. Every number below carries its command.
- **The answer is a PLACEMENT fix, not a destination.** #258's third direction
  asks for a place for the findings `upstream` calls `unplaceable`. Counted, the
  bucket holds zero consumer product findings: where a finding has a fix path on
  a consumer-owned file it is already served by `cmd_feedback` and the
  PreToolUse hook, and where it has no path it cannot be keyed by anything. So
  the graduation records that the destination exists and names the two
  misclassifications that make it look empty.
- **The two defects go in a plan, not this branch.** Both are in `joharness.sh`,
  which `./joharness.sh protocol-paths` names; this session is bound unattended
  and cannot commit there. Plan is SUPERVISED ONLY.

## Rejected

- **Building #258's destination.** It would serve a bucket whose placeable
  members already have a reader and whose unplaceable members have no key. The
  issue's own "largest change and the one that fits the existing design best"
  is, on this corpus, a destination for nothing.
- **Narrowing `upstream_text_paths` to kill the junk tokens.** 142 of the 151
  text-path findings resolve to nothing real (`origin/main` 20, a bare `/` 8,
  `precision/recall`, `before/after`). Tempting, and wrong: it would also drop
  the 44 that name a canonical-owned file. The predicate that decides OWNERSHIP
  is what is wrong, not the one that finds tokens.
- **Claiming 45 missed-owned findings.** My first count resolved a token by
  suffix, so `docs/handover/README.md` — a real path in every consumer —
  matched `.agents/docs/handover/README.md`. Recounted on bare basenames and an
  exact `./`-strip only: 44.

## Review

- r1: (session) my first missed-owned count was 45, resolved by a regex
  anchored `(^|/)<token>$` — a SUFFIX match, not a basename. It paired the token
  `docs/handover/README.md`, which is a genuine consumer-owned path in every
  repo running this harness, with `.agents/docs/handover/README.md`, and would
  have reported a consumer's own file as canonical's. Recounted with bare
  basenames (no slash) and an exact `./`-strip only: **44**, one fewer
  (`wc -l < missed-strict.txt`, 2026-10-08). The overclaim was in the direction
  that matters — it inflated the defect I was about to file. (fixed — recounted
  to 44, and the acceptance bar now pins `docs/handover/README.md` as the
  regression case.)
- r2: (session) the plan shipped with no consumer-side acceptance check.
  `./joharness.sh ci` names it — `upstream-placement-defects: SHIPS to
  consumers — joharness.sh, shared:.agents/docs/feedback.md`, and the stage
  says a shipping plan's Acceptance must name the check a consumer runs
  (`ci.txt`, this tree, 2026-10-08; `ci: pass`, so advisory, not red). It
  bites harder here than the generic rule suggests: the one entrypoint the
  plan changes cannot be exercised in canonical at all, because
  `cmd_upstream` returns early on `JOHARNESS_CANONICAL=1`. A plan whose
  acceptance is all local would be green in the only repo where the changed
  code never runs. (fixed — Acceptance now requires the stripped-conf
  fixture run and the 44 appearing under `harness findings`.)
- r3: (session) `origin/main` moved 9 commits mid-branch (PR #316), so the
  corpus the graduation cites was no longer the corpus the merge lands on.
  Re-ran the whole sweep after merging: 273 edges, 2005 findings,
  1356 / 119 / 530, and the 530 split unchanged at 379 pathless and 151
  text-path, 44 missed-owned, 9 real, 0 durable consumer product file. Only
  the two totals and the kept count moved. Figures updated and the section now
  says the totals climb with the corpus while the third row is what the answer
  rests on. (fixed — and the catch was the step 4 periodic re-fetch, not luck.)
- r4: (session) "another repo's `README.md`" undersold the 9. Two of them are
  `README.md` and only one of those is another repository's (gastown); the
  other is a queue-directory README, and one more is `docs/product/`, a
  directory my prose did not list. Reworded to what the 9 actually are. The
  load-bearing word is `durable`, and it survives: none is a consumer-owned
  product file. (fixed — reworded, and the 9 is now A=8 under the stated
  partition, r6 below.)

- r5: (verifier) **"142 of the 151 resolve to nothing real" refutes itself in
  its own sentence.** The 142 was my JUNK count, where no token literally
  equals a tree-or-history path — and the 44 missed-owned findings are all in
  it, because `./joharness.sh` and `selftest.sh` are not literal tree paths
  either. That is the same reason `upstream_harness_path` rejects them. So the
  figure counted the 44 as unreal while the very next clause ("a tokenizer
  tightened to drop those drops the 44 with them") depended on their being
  real. Re-counted: `142 - 44 = 98` by that method, and 86 under the stated
  partition. Three copies of the bad number in the diff, and it was the only
  quantitative support for the plan's `Out of scope` bullet. (fixed — replaced
  by the A/B/C/D partition table, whose rule is written down beside it.)
- r6: (verifier) **the 9 and the 0 had no recorded method anywhere in the
  diff**, so neither could be re-counted — `.agents/docs/research/README.md`:
  "an unrecorded method is a failed file… its findings may still be right, and
  nobody will ever be able to tell". Only the 44 was reproducible, and only
  because r1 happened to state its rule. The verifier got 14 where I had 9,
  and nothing in the diff could adjudicate it. (fixed — the 151 now partition
  A=8 / B=44 / C=13 / D=86 under one stated resolution rule, summing to 151,
  and the table carries the rule.)
- r7: (verifier) **the zero was load-bearing and could not have been anything
  else.** `upstream_harness_path` rejects 20 of this tree's 142 files; drop the
  retiring queue nodes and six durable ones remain, none of them product code,
  because canonical HAS no product code. My caveat said "the shape
  generalizes" and listed the two things that do — it never said the zero does
  not, which was the one figure the answer rested on. (fixed — the zero is
  demoted to illustration and the section now says in so many words that the
  corpus could not have held a counter-example. The conclusion is re-derived
  from the fix-path dichotomy, which rests on `cmd_upstream`'s branches and
  `cmd_feedback`'s key rather than on any headcount, and so survives. Graded
  UNGROUNDED in the graduation.)
- r8: (verifier) **the stated cross-check does not reproduce from the command
  it names.** Plain `./joharness.sh feedback` reads only `FB_LIMIT` edges
  (default 50) and prints `530 findings` over `44 carrying a workstream file`;
  the 2005 / 224 totals need `JOHARNESS_FEEDBACK_EDGES=0`, which I never wrote
  down. Worse, the 530 a reader actually sees is the same integer as the
  unplaceable row three lines below, so running the quoted check reads as
  confirming a row it never counted. (fixed — the flag is in the command block
  and the collision is named.)
- r9: (verifier) **the plan's basename rule manufactures 13 false negatives.**
  "Ambiguous basename, or more than one match: reject, as now" rejects
  `handover-context.sh` (5), `queue-context.sh` (4) and `TEMPLATE.md` (4) —
  every tree match of each is canonical's, so the OWNERSHIP verdict is not
  ambiguous even though the path is. So the true count is 57, not 44, and my
  `## Traps` entrenched the gap while `## Where to look` quoted the comment
  that forbids it ("a false negative loses the finding entirely"). (fixed —
  the rule now resolves ownership rather than path uniqueness, rejects only a
  MIXED match set, and 44 → 57 in both files.)
- r10: (verifier) **defect 1 called documented intent a defect.** The code says
  on purpose that a text-placed finding on no canonical path "is not a finding
  about this repo's own files — it is a finding nothing placed", and the
  routing follows from that. The demonstrable defect is the HEADING, which
  asserts of 151 findings something their own text refutes; PR315's `r8` is
  evidence of the false label, not of a misrouted finding, since
  `precision/recall` places nothing. (fixed — defect 1 reframed as labelling,
  the code comment quoted rather than ignored.)
- r11: (verifier) **`scope:` was incomplete.**
  `.claude/commands/upstream-report.md:45` carries the same false sentence the
  plan fixes, so an implementer following the plan would leave the reporter's
  own doc asserting behaviour the code no longer has. It is already a protocol
  path, so declaring it costs nothing. (fixed — added to `scope:` and to
  `## Scope`.)
- r12: (verifier) **`shared:` on `.agents/docs/feedback.md` was justified by a
  reason the protocol does not recognise.** I wrote "because it is the
  graduation target"; `shared:` means a reconcile merge is routine there, and
  marking a path that way claims a parallel safety the plan does not have. No
  concurrent plan touches the file and the question retires in this same diff.
  (fixed — mark removed, reason recorded in `## Scope`.)
- r13: (verifier) **"Both limits above are weaker than the code" was false of
  one of them.** The multi-finding-fix-commit bullet matches
  `upstream_multi_ids` and the `flag=` assignment; nothing in the diff showed
  it wrong, and the two defects did not correspond to the two bullets anyway
  (defect 2 is about `upstream_harness_path`, which neither bullet describes).
  (fixed — the claim is gone with the rewrite, and the plan now names the
  second bullet only, saying why the first is not in question.)
- r14: (verifier) **the research closure graded nothing GROUNDED / WEAK /
  UNGROUNDED**, which `.agents/docs/research/README.md` requires, and r5 and
  r7 are exactly the refuted-claim shape the three-word vocabulary exists to
  catch. (fixed — the graduation ends with the grading, and both refuted
  claims are recorded there as UNGROUNDED rather than quietly corrected.)
- r15: (verifier) **the 100-line section split the host section's 1-5
  sequence**, landing between `### 4.` and `### 5.` and pushing item 5 a
  hundred lines away from items 1 to 4. (fixed — moved after item 5, where it
  reads as the section's conclusion.)
- r16: (verifier) three consecutive blank lines before the bucket table, an
  artifact of the re-count edit. (fixed with the rewrite.)
- r17: (verifier) step 5's record was owed at the time of its report: the
  graduation was already committed into shipped protocol text with no
  second-context pass on any of its numbers, and `JOHARNESS_REVIEW=off` means
  nothing would have redded it. r5 and r7 are what that pass was for — one
  self-refuting figure and one load-bearing claim that could not have failed.
  (fixed — this record, and every finding above answered in the same commit.)
- r18: (verifier) **the re-count updated `.agents/docs/feedback.md` and not
  the plan**, so `## Goal` still said "272 merged edges" and pointed an
  implementer at a section that disagreed with it. The same commit that moved
  272→273 and 1984→2005 in one file left the other behind — a figure copied
  into two files is a figure that goes stale in one. (fixed — 273 and 57 in
  both, and the plan now cites the section rather than restating its table.)

## Blockers

None. Step 5 complete: 18 findings, 14 of them the opus verifier's, every one
answered in the commit that recorded it. `verify` green (6 passed, 0 failed)
though this diff is `*.md` only and step 7 does not require it.

## Where to look

- `docs/research/where-a-consumers-own-findings-go.md` — the question, its
  `What would settle it`, and its `Method` clause saying this repo cannot
  answer it from its own checkout (`JOHARNESS_CANONICAL=1`).
- `joharness.sh:cmd_upstream` — the three-way split whose boundaries the
  question says are not where a reader expects.
- `joharness.sh:cmd_feedback` — the reader that already serves path-keyed
  findings out of merged history.
- `.agents/docs/feedback.md` — graduation target.

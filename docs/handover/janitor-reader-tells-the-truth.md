---
workstream: janitor-reader-tells-the-truth
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: 278
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-10-07
next: ci is green and the mutations bite; retire this file and open the pull request
---

## Goal

Requester, 2026-10-07: "Fix and continue." Four issues had been filed from
three janitor sweeps and a curate pass and none fixed, because each role
forbids touching code. This session is in none of those roles, the repo is
supervised, and the boundary that bars protocol text is the unattended one —
so the fixes are available here.

Taken: **#278 and #288**, which are one pattern in one function. `cmd_janitor`
printed two conclusions about state it never read.

- `holds: docs/plans/<x>.md, out of the queue while this claim stands`, from
  the claim's `plan:` field alone. False whenever the plan lives only on the
  claim's own branch, which is the normal shape — plan and claim are written
  together. Wrong on 5 of 5 candidates in the 2026-09-17 sweep, which counted
  them itself (`git log -1 6203dc3`), and on "the only candidate that names a
  plan" in the 2026-10-07 sweep, whose r2 counts that
  (`git show 1d458fa:docs/handover/janitor-2026-10-07.md`). TWO sweeps measured, one
  silent — the 2026-10-05 sweep's record counts the throttling verdict and not
  this line.
- `pull request N — nearly done, not abandoned work`, from the field's
  presence alone. Said of a pull request closed without merging seven weeks
  earlier — `closed`, `merged: false`, closed 2026-08-21, which is 47 days
  before that sweep and is in its own record, not in the merge commit
  (`git show 1d458fa:docs/handover/janitor-2026-10-07.md`, Decisions) — while `drain`
  said "state unverified" about the same field. The three-cycles figure is the
  one `git log -1 b8a872a` carries, and it is the `pr:` line's figure and not
  the `holds:` line's; I had carried one number across both.

## Decisions

- **Step 3 was skipped and this file is late.** The build started without a
  claim. Recorded rather than quietly backdated: the Stop guard caught it,
  which is the guard working.
- **#278 and #288 together, #279 not.** The first two are one function and one
  pattern — a reader asserting state it never read — so one diff reviewed as
  one idea. #279 is a different family (a word that reached one reader and not
  others) and would make this diff two changes wearing one title.
- **`holds:` gains a FOURTH case, and asks the branch too.** It began as three
  (r4, r5). Four probes, two refs: `docs/plans/<x>.md` and
  `docs/research/<x>.md` against `refs/remotes/origin/<base>`, then the same
  two against the claim's own branch. The reader has no network and needs
  none — every one of these is a local question — and WHICH path it names
  matters as much as where it is.
- **The `pr:` line keeps the exemption and drops the claim.** Naming a `pr:`
  is what makes the work Loop step 2's, whatever the state — so it says that,
  and says the state is unreadable here, which is what `drain` already says.

## Rejected

- **Making `janitor` read the pull request's state.** It would be the better
  sentence and it needs a token and a network call in a reader that
  deliberately has neither. The honest wording costs nothing.
- **Marking the third case a defect of the claim.** A plan on an unmerged
  branch is not a mistake by its author; it is how an unmerged branch works.
  The line now says what releasing buys, not that anybody erred.

## Review

- r1: (session) **the first fixture silently tested nothing.**
  `git checkout main` removes `docs/handover/` once it is empty there, so the
  new case's redirect failed and only its plan was committed — the branch was
  never a candidate, and three assertions failed for a reason that looked like
  the fix being wrong. The working `parked` fixture does `mkdir -p` first and
  I had dropped it. Found by probing the fixture's index at commit time
  (`status --porcelain` showed `?? docs/plans/ownplan.md` and `ls` showed the
  directory absent), after three cheaper probes that only narrowed it.
  (fixed — `mkdir -p` restored, with a comment saying why it is there, since
  the failure mode is a silent redirect rather than an error.)
- r2: (session) **the first mutation proved nothing and looked like proof.**
  `elif true; then` on a line that was a multi-line `elif git ... \`
  continuation orphaned the next line, broke the script, and redded **1010
  cases** off a green baseline. A mutation that reds a thousand cases says
  nothing about one clause. (fixed — the second mutation appends
  `|| true` to the condition's own line, keeping the syntax valid so only the
  cases that depend on the clause can red. Verdict: baseline green, then
  **4 case(s) redded** — exactly the four assertions about the new third
  case, and NOT the control that asserts the true sentence still appears for
  a plan the base branch does carry, which making the condition always true
  cannot affect. Precise, which is what the first mutation was not.)
- r3: (session) **the `pr:` change was not mutation-tested, deliberately.** It
  is a string, and its test asserts that string, so a mutation of the string
  reds the assertion by construction and proves nothing a reader cannot see.
  What the test adds beyond the expect is the refute on "nearly done" — the
  old wording — which pins the regression rather than the clause. Said here
  rather than left as an implied "both were mutated". (no change.)

- r4: (verifier) **a claim's `plan:` names research questions too, and the
  first fix probed only `docs/plans/`.** So a claim holding an open question
  read "which main does not carry — on this branch only, so releasing frees
  nothing", about a question `main` does carry and the queue really does lose.
  The field's own spec says so (`.agents/docs/handover/TEMPLATE.md:22-23`, "A
  research file under `docs/research/` is claimed through this same field, by
  its stem"), and the two-candidate loop was already spelled four thousand
  lines away in this same file (`joharness.sh:7226`, `cycle_landed_sha`). My
  fix replaced one false sentence with another on a whole class of claim.
  (fixed — both probes, in a loop, and the line now prints the path it FOUND
  rather than a `docs/plans/` path it assumed. New selftest case: a claim on
  `docs/research/aquestion.md` must read "out of the queue while this claim
  stands" and must never read "which main does not carry".)
- r5: (verifier) **"on this branch only" was asserted from the base tree
  alone.** Not finding the plan on `main` does not put it on the claim's
  branch; a typo, a rename, or a plan never written all land in the same
  `else`, and the line then sent an operator to look for a file that is on no
  branch at all. Ownership is a DIFF, never a tree read, and six merged edges
  bought that rule (`.agents/docs/feedback.md`, "Worked example: tree or
  diff") — which I had read this session and still did not apply.
  (fixed — the branch is probed as well, and a fourth case says "named, which
  no branch carries — a typo, a rename, or never written: resolve it by hand".
  Selftest case `mgr-ghost` asserts it; mutation
  verdict below.)
- r6: (verifier) **my base-branch selftest case was vacuous and I counted it
  as coverage.** It ran `jan HANDOVER_BASE_BRANCH=main` — the DEFAULT — so the
  same code path ran with or without the parameterisation. `mutate` on the
  `does not carry` message line — `joharness.sh:5347` at e7f645c, a pointer
  this commit's own edits have since moved, which is why the line is named by
  its text — returned NOTHING REDDED, which is the proof: real coverage was three assertions, not the four r2's verdict
  implies. (fixed — the fixture now pushes the same commit as `trunk` and
  asserts "which trunk does not carry", with a refute on the hard-coded
  `main`. The verifier confirmed in its own fixture that the code is right
  that way before I changed the test, so this is a test fix and not a code
  fix.)
- r7: (verifier) **`plan:` is branch-controlled frontmatter printed straight
  out, and `lint_stem` does not sanitise it.** `lint_stem` keeps everything
  after the last slash, so a payload carrying a slash and a newline forged the
  very sentence the four cases exist to withhold. PR275 r6 was this class on
  this same function, which is what makes it a repeat rather than a surprise.
  (fixed — `plan:`, `pr:` and `session:` go through `tr -cd` with the
  character set each one can legitimately hold. Only `plan:` has a case:
  it is the one that reaches a path and can spell a sentence, and r21 records
  why the other two do not need one.)
- r8: (verifier) **the pull-request line had no negative test.** Its `expect`
  fires on a candidate that HAS the field; nothing asserted that a candidate
  without one gets no line, which is the other half of "the field's presence
  is what makes it exempt". (fixed — counted, not refuted: three of the
  candidates at the end of the fixture have no `pr:` and a bare refute on the
  string would also pass in a sweep that printed the line for somebody else.)
- r9: (verifier) **two printed lines ran past 120 characters.** A sweep's
  report is read in a terminal. Re-measured 2026-10-07 by piping each
  round-one `printf` through `awk '{print length($0)}'`: the pull-request line
  with `pr: 42` is **126**, and the `holds:` third case is **123** with the
  fixture's `ownplan` and **141** with the longest stem any real claim names.
  I first wrote 125 for the second, which no input produces. (fixed — both
  split, with the continuation indented under its own line.)
- r10: (verifier) **"nearly done" reached a second reader and I fixed only the
  first.** `.claude/commands/janitor.md:63-65` told the role the same false
  thing — "an open pull request means the work is nearly done" and "report it
  as edge work waiting for somebody" — so a sweep following the role doc would
  have written back the sentence the code had stopped printing. One rule, two
  readers, and #279 is the family: a word reaching one reader and not the
  others. (fixed — the clause now says naming the field is what makes it
  exempt, that the state is unreadable here, and what #288 was.)
- r11: (verifier) **the Goal's "three sweeps running" was one number carried
  across two claims.** The `holds:` line is counted in two sweeps (5 of 5 on
  2026-09-17, 1 of 1 on 2026-10-07) with the middle sweep's record silent on
  it; three cycles is the `pr:` line's figure. A written number, in the file
  that argues against written numbers. (fixed — both figures now carry the
  `git log -1 <sha>` that re-counts them, here and in the selftest's comment.)
- r12: (verifier) **I never ran step 4's `feedback` on the file I was about to
  change, and it already held the answer to r1.** `./joharness.sh feedback
  .agents/harness/selftest/janitor.sh` carries PR275 r2 — a fixture whose
  redirect failed silently because `docs/handover/` was gone. I rediscovered
  it from scratch, after three narrowing probes. The rule exists because this
  is cheaper to read than to re-derive, and the cost is now measured on this
  branch. (no change — the rule is right and the omission is mine. Recorded so
  the file's feedback carries a second instance, which is what graduates a
  rule.)
- r13: (verifier) **`issue: 278` cannot express that this also closes #288.**
  The frontmatter field is singular, so the hook's CLAIMED list shows #278
  and not #288, and a concurrent session reading that list would have taken
  #288 as free. Not fixed here: a second field, or a list, is a protocol
  change to the handover template and to two readers of it, and that is its
  own plan. (wontfix — recorded, and the pull request body names both so the
  merge closes both.)

- r14: (verifier) **case 4 said "which no branch carries" from two
  `cat-file` calls.** A plan authored on a sibling branch and not yet merged —
  session A writes `docs/plans/x.md` on an unmerged branch, session B claims
  `plan: x` from `main` — produced "a typo, a rename, or never written:
  resolve it by hand" about a plan that exists. That is #278's own shape, a
  conclusion about state the reader never read, in the sentence this round
  added to fix #278, and it is worse than cases 2 and 3 because it tells a
  human to go act on it. (fixed — the sentence now claims exactly the two refs
  it read: "which neither <base> nor this branch carries — a typo, a rename, or
  a plan on some other branch". Refute added on "no branch carries".)
- r15: (verifier) **"on this branch only" was never checked either, and the
  data that falsifies it is on origin now.** Counted 2026-10-07 on this
  checkout: `docs/plans/unsupervised-endurance.md` is carried by **20** origin
  refs and not by `main` (`for r in $(git for-each-ref
  --format='%(refname)' refs/remotes/origin); do git cat-file -e
  "$r:docs/plans/unsupervised-endurance.md"; done | wc -l`); `marker-gate-
  needs-no-done` 9, `guard-docs-only-branch` 6, `frontmatter-forge` 1. So for
  the claim naming the first, the word "only" was false by 19. Five of those
  six claims read `abandoned` today and are skipped, so no sweep has printed
  it yet — but the protocol lets a returning session set a released claim back
  to `in-progress`, and then it prints. (fixed — the word is gone; the
  consequent, which the probes do support, stays: "so releasing this claim
  frees nothing in <base>".)
- r16: (verifier) **the `trunk` fixture pinned the format string, not the
  probe.** `git push origin main:trunk` makes `trunk` and `main` the SAME
  COMMIT, so both `cat-file` loops return identical answers and a mutant that
  hard-codes `main` inside the two ref strings while leaving `"$base_branch"`
  in the `printf` passes every assertion. r6's defect in a new spelling, on the
  second attempt at the same case. (fixed — `trunk` now has different CONTENT:
  it is `main` minus `docs/plans/parked.md`, so the claim on that plan must
  change case with the base branch, with a control asserting it reads the other
  way under the default.)
- r17: (verifier) **`.claude/commands/janitor.md` had the `pr:` half of the
  two-reader problem fixed and the `holds:` half left.** Three places still
  told the role a release frees a plan — "The plan is free the moment the queue
  hook reads that word", a release note carrying "the plan it was holding", and
  a report line asking for "the plan each freed". For every candidate the code
  now routes to case 3 or 4, which the diff's own argument says is the normal
  shape, all three are false, so the role would have written the sentence back
  by hand into the note and the report. r10 fixed one reader of one half.
  (fixed — all three now say to copy the `holds:` line's own words, and the
  release paragraph says releasing frees nothing in the queue for the normal
  shape.)
- r18: (verifier) **the same false universal is in four more files** —
  `.agents/docs/orchestrated.md:42` ("A claim whose session is gone holds its
  plan out of the queue for ever"), `.agents/scripts/conf-keys.sh:53`,
  `joharness.sh:150`, `.agents/scripts/bootstrap-consumer.sh:814`. (wontfix
  here — this is #279's family, a word reaching one reader and not the others,
  and four files across two layers is a wider change than the one this branch
  claimed. Filed rather than widened.)
- r19: (verifier) **the branch probe ran even when the base probe had already
  found the file**, though the case that reads it is unreachable then — forty
  wasted `cat-file` calls for twenty candidates whose plans are all in the
  queue. Noted against a comment four lines above citing PR275 r11 as a perf
  finding on this same function. (fixed — `[ -z "$held" ] ||` guards it.)
- r20: (verifier) **the sanitiser decided case 1, so a claim that named a plan
  could be reported as naming none.** `plan: 計画` is entirely outside the
  character set, so `tr -cd` emptied it and the reader said "no plan — this
  claim holds nothing but its branch". A third false sentence, introduced by
  the commit removing two. (fixed — presence is captured before the strip, and
  a fifth case says the field cannot be printed and tells the operator not to
  read "no plan" into it. Fixture `mgr-unprintable` pins it, with the refute
  scoped to that candidate's own block because other fixtures legitimately
  read "no plan".)
- r21: (verifier) **`pr:` and `session:` are sanitised and untested**, though
  r7 claims all three. Verified by the reader that nothing legitimate is
  stripped today: every `pr:` value across every origin ref is a bare number or
  `none`, and real session URLs survive intact — but a `pr:` spelled as a URL
  would print as `pull request httpsgithub.comxypull42`. (no change — only
  `plan:` reaches a path and can forge a sentence, which is why only it has a
  case. The claim that all three were tested is corrected to name the one that
  is.)
- r22: (verifier) **a plan in a subdirectory would land in the wrong case.**
  `plan: docs/plans/sub/x.md` stems to `x`, probes `docs/plans/x.md`, and reads
  case 4 while the branch carries the file. Latent, not live: the queue globs
  one level. (wontfix — recorded; a nested plan is outside what the queue
  protocol admits, and inventing a probe for it here would be inventing work.)
- r23: (session) **three rounds, and each one's fix carried the same class of
  defect.** Round 1 printed two sentences from state it never read. Round 2
  fixed those and printed two more (r14, r15). Round 3 fixed those and the
  sanitiser printed a third (r20). I checked this against the churn rule
  (`.agents/docs/agent-selection.md`): it is NOT churn as the rule defines it —
  no round broke what an earlier round established, and the findings are one
  consistent class rather than oscillating requirements. The conflict is not
  between requirements; it is that the better-sounding sentence is always the
  stronger one, and I kept reaching for it. The rule that converges, applied
  uniformly this round: **every printed sentence names no more refs than the
  reader actually read.** Cases 3 and 4 now say "<base>" and "this branch"
  explicitly, which is why they cannot rot when a third branch appears.
  (fixed — as the wording of all five cases, not as another case.)

## Verification

Counted, with the command and the date, because this file argues against
written numbers.

- `bash .agents/harness/selftest.sh`, 2026-10-07: **2208 passed, 0 failed**
  at a94c4b8. The 2198 baseline is the same command at e7f645c; what makes the
  difference re-countable without re-running either is
  `git diff e7f645c a94c4b8 -- .agents/harness/selftest/janitor.sh |
  grep -cE '^\+(expect|refute) '` = **10**, with 0 removals.
- Mutation verdicts, `./joharness.sh mutate joharness.sh <line> <text>` against
  38d88b2 on 2026-10-07. Every baseline green first; a mutation that reds
  hundreds of cases proves nothing about one clause, which is r2's lesson.
  - the `docs/research/` candidate dropped from the base probe: **2 redded** —
    the research-question case and its refute.
  - `${base_branch}` replaced by a literal `main` in the base probe, leaving
    `"$base_branch"` in the message: **2 redded**, both `latecomer`
    assertions. This is the exact mutant the verifier demonstrated SURVIVED
    the `main:trunk` fixture (r16). It no longer survives, which is what makes
    the third spelling of that case the first real one.
  - the branch probe pointed at the base ref: **3 redded** — case 3's two
    assertions and `latecomer`'s, case 3 collapsing into case 2.
  The `pr:` wording and the five case STRINGS are not mutation-tested, by
  choice: a mutation of a string reds the assertion that quotes it by
  construction and proves nothing a reader cannot see (r3).

- r24: (session) **three of my own fixtures were wrong, and two of them would
  have passed while testing nothing.** The suite caught all three (2212 passed,
  4 failed, `bash .agents/harness/selftest.sh` at this tree before the fix).
  The `trunk` fixture DELETED a plan file, which is the retired-edge-branch
  signature, so the hook read `trunk` as a manager in flight and the free-slot
  assertion two sections down failed — correctly, and for a reason that had
  nothing to do with what the case was testing. `printf '\u8a08'` never
  expanded, so the unprintable-field case fed the reader an ordinary stem
  (`u8A08u753B`) and would have gone green over the wrong input. And one
  `expect` spanned a `printf` line break, so it could never match. (fixed —
  `trunk` is now main-as-it-was with the plan arriving afterwards, the fixture
  carries literal UTF-8 bytes, and the expect stops at the line break. Third
  time this branch has caught a fixture that tested nothing: r1, r6/r16, and
  now this. The pattern is mine, and it is the same one as r23 — the fixture I
  reach for first is the one that looks right rather than the one that
  discriminates.)

- r25: (session) **my refute forbade a substring the correct output must
  contain.** The fifth case's line quotes `"no plan"` in order to tell the
  operator not to read it there, so `refute ... "no plan"` failed against the
  only output it was meant to accept — the code was right and the assertion
  could never pass (2214 passed, 1 failed, `bash .agents/harness/selftest.sh`
  at 817fb81). A refute has to name the SENTENCE, not words the right answer
  also uses. (fixed — anchored on `holds: no plan`, which the correct line does
  not contain and the defect does.)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_janitor` — the candidate block, both printed lines.
- `.agents/harness/selftest/janitor.sh` — the `parked` fixture is the case
  where the old `holds:` line was TRUE, which is why nothing caught it.

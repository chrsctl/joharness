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
next: Three mutations prove the new probes and the trunk case bite (one running), then ci, verify, a second reader on the changed diff, retire, pull request
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
  them itself (`git log -1 6203dc3`), and on the one plan-naming candidate of
  the two the 2026-10-07 sweep walked (`git log -1 b8a872a`). TWO sweeps
  measured, one silent — the 2026-10-05 sweep's record counts the throttling
  verdict and not this line.
- `pull request N — nearly done, not abandoned work`, from the field's
  presence alone. Said of a pull request closed without merging seven weeks
  earlier and re-derived as closed in three cycles before being filed
  (`git log -1 b8a872a`), while `drain` said "state unverified" about the same
  field. Three cycles is the `pr:` line's figure and not the `holds:` line's;
  I had carried one number across both.

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
  message line (`joharness.sh:5347`) returned NOTHING REDDED, which is the
  proof: real coverage was three assertions, not the four r2's verdict
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
  character set each one can legitimately hold, matching what the in-flight
  walk above already does to `workstream:` and `status:`. Selftest case
  `mgr-forge` refutes the forged sentence.)
- r8: (verifier) **the pull-request line had no negative test.** Its `expect`
  fires on a candidate that HAS the field; nothing asserted that a candidate
  without one gets no line, which is the other half of "the field's presence
  is what makes it exempt". (fixed — counted, not refuted: three of the
  candidates at the end of the fixture have no `pr:` and a bare refute on the
  string would also pass in a sweep that printed the line for somebody else.)
- r9: (verifier) **two printed lines ran past 120 characters.** A sweep's
  report is read in a terminal, and the four-case `holds:` line plus the
  pull-request line were 125 and 126. (fixed — both split, with the
  continuation indented under its own line.)
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

## Verification

Counted, with the command and the date, because this file argues against
written numbers.

- `bash .agents/harness/selftest.sh`, 2026-10-07: **2208 passed, 0 failed**.
  2198 before this round, so the ten new assertions all land.
- Mutation verdicts for the three new clauses — the `docs/research/` probe,
  the branch probe, and the `trunk` parameterisation that replaced the vacuous
  case — are NOT in this commit. The first run was stopped with the file
  intact rather than risk committing a mutated line mid-run, and they are
  re-run against this committed tree. An assertion that passes is not yet an
  assertion that bites, and r6 is this branch's own evidence for the
  difference.

## Blockers

None.

## Where to look

- `joharness.sh:cmd_janitor` — the candidate block, both printed lines.
- `.agents/harness/selftest/janitor.sh` — the `parked` fixture is the case
  where the old `holds:` line was TRUE, which is why nothing caught it.

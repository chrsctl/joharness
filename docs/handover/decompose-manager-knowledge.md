---
workstream: decompose-manager-knowledge
status: in-progress
branch: claude/decompose-manager-knowledge
pr: none
plan: none
issue: 258
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-10-07
next: Retire this file and open the pull request
---

## Goal

`drain` named `docs/plans/unowned-block-age.md`, but Loop step 2 puts open
GitHub issues ahead of plans and `drain` does not read GitHub. Checked: of the
14 open issues, #249, #251, #254/#257, #267, #271 and #273 already have a plan
or an open question. The oldest with NO decomposition is **#258**
(2026-09-16), "A manager's closing report is three words — everything it
learned is discarded on success and delivered only on failure".

Nothing builds unplanned, so decomposing it IS this item.

Step 2's first clause is "Finishing outranks starting", so the in-flight block
was read before the issue list: its one `pr:`-bearing entry,
`claude/multi-agent-orchestration-pr-jyli0w`, reads `status: abandoned` —
released at Loop step 2 under an earlier drain item with the requester's
authorisation, recorded in PR294. Nothing there is unfinished.

## Decisions

- **Two of #258's three directions have already landed, and the plan says so
  rather than re-proposing them.** Every claim in an issue is a hypothesis
  until checked against current code; this one is three weeks and many merges
  old.
  - Option 1, widen the merge message → DONE in `f083aa0`, whose message says
    "Issue #258's first option". `.claude/commands/manage.md` §4 defines
    `lead <stem>: <text>`. It is NOT the whole of the issue's case: #258
    measured three findings about three queue items, and §4 says "One lead,
    not a list" at 40 characters.
  - Option 2, make the loss visible at `finish` → DONE in `436d3a1`, whose
    message says "Issue #258, option 2". `joharness.sh:fin_promote` prints the
    finding count and the promotion count.
  - Option 3, give the findings a destination → OPEN. This is what the plan
    scopes.
- **The issue's central factual claim is now false, and that narrows it.** It
  says the findings are "written down properly and then destroyed on merge".
  They are not: `joharness.sh:cmd_feedback` serves findings out of
  merged history keyed by path. Verified by running
  `./joharness.sh feedback joharness.sh`, which returns findings from merged
  edges including `6b0a210`. So the loss is narrower than filed: what has no
  home is the finding that names no path this repo owns — `upstream` lists it
  as `unplaceable` and says in its own output that it "will not guess".
- **A research file, not a plan — decided after the review (r1, r12).** Option
  3 is a DESTINATION question and the destination is undecided, so there are no
  acceptance criteria to write: a plan would have to invent the answer it is
  supposed to deliver. `docs/research/scheduler-outside-the-fleet.md` is #249's
  undecided half for the same reason. The question graduates into
  `.agents/docs/feedback.md`, beside the three buckets it is about.
- **This repo cannot answer it, and the file says so.** `cmd_upstream` returns
  early under `JOHARNESS_CANONICAL=1`; the counting has to happen against a
  consumer edge or a fixture whose conf omits the key. My first draft asserted
  output this checkout cannot produce (r5).

## Rejected

- **Implementing option 3 in this item.** Decompose IS the work (step 2). A
  session that decomposed and then built would be two items.
- **The first draft's plan, `finding-with-no-path-has-no-reader.md`.** Withdrawn
  whole rather than patched: it scoped option 2 under option 3's name (r1), and
  four of its six acceptance items could not be run in this repo (r4, r5, r7,
  r8). Patching the label would have left the mismatch.
- **Closing #258 as done.** Two directions landed and the third did not; the
  issue's own summary calls option 3 "the real fix". Closing it would discard
  the part nobody has addressed.

## Review

- r1: (verifier) **the plan said it scoped option 3 and delivered more of
  option 2 — so implementing it and closing #258 would leave the issue's own
  "real fix" unbuilt.** `git log -1 436d3a1` says in its own message "Issue
  #258, option 2" about the promotion block my plan set out to extend, while
  the plan's Out of scope said of option 2 "Do not re-propose them, and do not
  improve them" two lines before saying "option 2 is the promotion block this
  plan extends". Option 3 verbatim is "Point `upstream` at the consumer too…
  What it lacks is a DESTINATION", and my Out of scope excluded exactly that.
  (fixed — the plan is withdrawn and replaced by a research file. A
  destination nobody has chosen cannot have acceptance criteria, which is why
  #249's scheduler is a question and not a plan either.)
- r2: (verifier) **the paragraph I added to declare the scope overlap was
  itself two false claims about a file I could have read.** I wrote that
  `unowned-block-age`'s `scope:` is "byte-identical" to mine and that "neither
  marks a prefix `shared:`". It reads
  `shared:joharness.sh, .agents/harness/selftest/dispatch.sh` — not identical,
  and it does mark `shared:`. I labelled the paragraph "declared rather than
  assumed" and it was an assumption. (fixed — withdrawn with the plan; the
  research file declares no scope overlap because it touches no code.)
- r3: (verifier) **`./joharness.sh curate` already reported my plan as
  defective, and `curate : DUE` outranks the queue — so the diff manufactured
  the next session's top item.** `scope:` named the bare directory
  `.agents/harness/selftest`, which `.agents/docs/plans/README.md` forbids.
  Before this diff curate had nothing to repair. (fixed — withdrawn; verified
  by re-running `curate`.)
- r4: (verifier) **ship-scope applied and my Acceptance named no consumer-side
  check.** `ci` printed `finding-with-no-path-has-no-reader: SHIPS to
  consumers — joharness.sh`, and all six Acceptance items were local. The rule
  is the gate; `ci` stayed green because the stage is report-only, so a green
  run was not evidence. (fixed — withdrawn.)
- r5: (verifier) **Acceptance 6 was unexercisable in the repo it ships from.**
  `cmd_upstream` returns early when `JOHARNESS_CANONICAL=1`, which
  `joharness.conf` sets — so no edge of this repo ever fills the `unplaceable`
  bucket my acceptance keyed on. Verified by running `./joharness.sh upstream`:
  "CANONICAL — this repo IS the harness… Nothing to route." The handover's
  claim that `upstream` "says in its own output that it will not guess" is not
  reproducible here. (fixed — withdrawn; the research file's method says the
  question must be answered against a consumer, not here.)
- r6: (verifier) **my three-bucket table's third row was wrong, and the Scope
  rule contradicted Acceptance 6 on a concrete input.** A finding
  `- r1: docs/product/foo.md says two things`, recorded in a commit touching
  only the workstream file, lands in `n_noid` (`upstream` calls it
  unplaceable) while carrying a path in its own text (my Scope rule says do
  not name it). The table also dropped the `from_text` case and the "no id to
  key on" clause. (fixed — withdrawn; the research file states the buckets as
  a question to settle, not as a table it asserts.)
- r7: (verifier) **Acceptance 4 would have redded whether or not the clause
  under test was correct.** It compared `finish` output against "the same
  command at the merge base", but `finish`'s first line names the branch and
  its body derives from this branch's own workstream files, so the two differ
  unconditionally. The runnable form is the merge base's SCRIPT against the
  current branch. (fixed — withdrawn; recorded because it is the same
  passes-for-the-wrong-reason shape as PR290 r6 and r16.)
- r8: (verifier) **Acceptance 3's fixture could have gone green vacuously** —
  nothing in it pinned the `## Review` heading that `fb_findings` requires,
  which my own Traps section names. (fixed — withdrawn.)
- r9: (verifier) **the handover cited line numbers where the house rule is
  symbols.** `joharness.sh:6235-6237` and `joharness.sh:3981` are correct
  today and rot invisibly, because `lint_anchors` checks the path only.
  (fixed — both now name `fin_promote` and `cmd_feedback`.)
- r10: (verifier) **"Measured twice on one branch: PR294 r12" was wrong about
  the branch count.** It was twice on one DAY across two pull requests, #289
  and #294. The substance held; the measurement attached to it did not.
  (fixed — the research file says "two sweeps, one day, two pull requests".)
- r11: (verifier) **"landed, and precisely on the issue's sharpest point"
  overstated, in a file whose own Traps forbid a claim with no command beside
  it.** #258's measured instance is three findings about three different queue
  items; `manage.md` §4 says "One lead, not a list" at 40 characters, so that
  case would have been truncated to one of three. (fixed — both landings now
  cite `f083aa0` and `436d3a1`, and the "precisely" claim is gone.)
- r12: (verifier) **the plan picked the wrong population out of #258.** The
  issue's unplaceable set is "genuinely good material about the consumer's own
  product"; a finding about a consumer's product whose fix touched product
  files lands in bucket 2, which HAS a reader. Bucket 3 is a smaller,
  different set. So "the third row is the one #258 measured hardest" was my
  reading, not the issue's measurement — and this is the mechanism behind r1.
  (fixed — the research file asks about the destination for the consumer's own
  findings, which is what the issue actually complains about.)
- r13: (verifier) **"nobody" was broader than what I had read.** Two readers
  exist for the path-free shape: `manage.md` §4 routes a stem-less lead to the
  pull request body, "which outlives you and which a human reads"; and
  `feedback` with no path argument already counts path-free findings and
  prints a line for the analogous no-id case. (fixed — both named in the
  research file's Sweep, and the no-id line is named as the existing idiom to
  reuse rather than reinvent.)
- r14: (verifier) **tier was under-argued: every path in my `scope:` is a
  protocol path, which `agent-selection.md` makes an `effort: xhigh` lever.**
  (fixed by withdrawal — the research file is opus/high per the template, and
  it touches no protocol path because it answers a question rather than
  editing code.)
- r15: (verifier) **the pick was right and independently re-derived, but the
  handover never recorded looking at the in-flight block first.** Step 2's
  first clause is "Finishing outranks starting". Confirmed: 14 open issues,
  #258 at 2026-09-16 22:42Z the oldest undecomposed; `ls docs/product/` does
  not exist so no requirement outranks the plans; no plan is blocked.
  (fixed — a Decisions bullet now records the in-flight check.)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_upstream` — where `unplaceable` is printed with no
  destination.
- `.claude/commands/manage.md` — §4, the `lead` line that closed option 1.
- `joharness.sh:cmd_feedback` — why "destroyed on merge" no longer holds.

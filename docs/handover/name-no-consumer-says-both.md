---
workstream: name-no-consumer-says-both
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: name-no-consumer-says-both
issue: 273
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Retire this file in the last commit before the pull request; the plan's direction is now the requester's to confirm or flip
---

## Goal

Issue #273, the oldest open issue with no queue item decomposing it.
`.agents/docs/consumer-repos.md`, `## Name no consumer`, answers one question
twice and differently, seven lines apart: `:207-209` says a consumer's pull
request numbers ARE covered by the naming rule, `:214-216` says they are NOT.

Step 2: nothing builds unplanned, and decompose IS the work. So this
session's item is the plan, not the fix.

## Decisions

- **Decompose rather than fix.** The Loop is explicit — an issue becomes a
  plan first. Small ask, small plan, still a plan.
- **The plan proposes an answer rather than parking on the human**, and the
  flag is an acceptance item rather than a sentence. A plan that names no
  direction is a plan nobody can pick up; a plan that decides one and never
  asks is a rule change nobody ratified. Both halves are needed, and the
  first draft had only the first.
- **The direction is NOT COVERED**, reversed from the first draft on r1-r3.
  What decides it is descriptive versus opaque: a repository, plan or item
  name says what somebody is building; a hash or a number says nothing
  without the repo, whose name is separately and absolutely banned. Three
  shipping lines in `.agents/docs/` already rest on a consumer's pull request
  number for provenance, so the other reading would make them non-compliant
  the moment it landed.
- **`agent: sonnet`, `effort: high`.** The judgement — which of two
  sentences survives — is made here; what is left is a text edit against a
  named rule. Tier confirmed by the reviewer against `agent-selection.md`
  (one unclear edge, so not haiku). Effort is the documented default, which
  the first draft downgraded with no reason recorded (r8).

## Rejected

- **Writing the fix in this session as well.** One item per session, and
  the decomposition is the item. A session that decomposes and then builds
  has skipped the step where a second reader can disagree with the
  decomposition before the code exists.
- **Leaving the direction open for the implementer.** Tried in the draft: an
  acceptance that reads "one spelling survives" passes whichever sentence is
  deleted, including the one that ships internal references. An acceptance
  that cannot fail in the expensive direction is not an acceptance.

## Review

- r1: (verifier) **the direction was WRONG, and the tree refutes its heaviest
  reason.** Reason 3 said the counting argument is served by commit hashes
  and not by pull request numbers. Re-checked here: `git grep -nE "PR ?#[0-9]+"
  -- .agents/docs` returns **three** shipping lines resting on a consumer's
  pull request number for provenance — `agent-selection.md:6` ("Developed in a
  consumer (its PR #3)"), `feedback.md:101` and `feedback.md:121`. A counted
  number in this repo rests on one today, in the directory the rule ships
  from. (fixed — the plan's direction is REVERSED, and those three lines are
  now evidence rather than violations.)
- r2: (verifier) **the counter-argument I never engaged is the one that
  decides it.** `:214-216` gives TWO rationales and I quoted only the second.
  The first — "opaque to anyone without the repo" — is the one that bears,
  because `:196` bans the repository name outright ("Do not write it"),
  which is not in dispute. With the name banned, a bare `#31` resolves to
  nothing. My asymmetry argument assumed a leak path a separate, undisputed
  rule already closes, and my own reason 2 conceded it: "a number plus a
  repository name anyone can guess" needs the name. (fixed — the plan now
  runs on the distinction the tree actually draws: DESCRIPTIVE identifiers
  are covered because they say what the work is; OPAQUE ones are not.)
- r3: (verifier) **reason 2 was self-cancelling and I presented it as
  second-heaviest.** `:207-209` lists pull request numbers beside plan names
  (covered); `:214-216` lists them beside commit hashes (not covered). Both
  are lists; the argument runs identically in both directions and decides
  nothing. (fixed — deleted, not rescued.)
- r4: (verifier) **the anchor pointed at a file that does not contain the
  rule.** "A measured number carries what produced it" is
  `.agents/harness/AGENTS.md:125`, not `graph.md`, whose `## Rules` says
  nothing about counted numbers — grepped both. `lint_anchors` stats the path
  only, so a wrong-in-content anchor stays green for ever. (fixed —
  re-anchored, and the same sentence is now cited where it is actually
  written.)
- r5: (verifier) **the veto I named was unreachable.** The plan said the
  requester may say otherwise and "that veto is the whole of what is open",
  and then no acceptance item, scope item or trap made anyone ask. Under
  `JOHARNESS_MODE=unsupervised` it would drain and merge with nobody asked.
  The precedent on this exact file is `PR252 r6 (verifier)`, which ends
  "Flagged to the requester as a decision rather than built." (fixed — the
  flag is an acceptance item now, and the decision was put to the requester
  in this session's own report. The verifier judged the DECIDING itself
  within authority — "Decide alone" lists stop-and-ask as money,
  credentials, hardware, product direction, merge conflict, and which of two
  doc sentences survives is none of those — so the defect was the missing
  flag, not the deciding.)
- r6: (verifier) **the plan SHIPS and its acceptance owed a consumer-side
  check it did not have.** `ci` says so in its own words on this branch:
  `name-no-consumer-says-both: SHIPS to consumers — .agents/docs/consumer-repos.md`,
  and the stage reports rather than reds, so `ci: pass` was no evidence
  against it. All four acceptance items were canonical-local. (fixed — a
  consumer-side item added.)
- r7: (verifier) **the acceptance contradicted the scope, and the correct
  minimal edit FAILED it.** Scope told the implementer to rewrite the
  exemption sentence; the acceptance pinned the literal string `Commit
  hashes` that the rewrite removes, with no expected output given. And after
  the minimal correct edit the `pull request number` grep returns ONE hit
  while the acceptance says to read both. (fixed — the acceptance is
  rewritten against the new direction, with the expected output written out
  for each command.)
- r8: (verifier) `effort: medium` is a downgrade from the documented default
  with no reason recorded — `agent-selection.md:27` says "Default = sonnet,
  effort high", the template ships `high`, and all four other plans in the
  queue are `high`. The tier `sonnet` it judged RIGHT. (fixed — `effort:
  high`.)
- r9: (verifier) two of the three line ranges the plan quoted were already
  stale on arrival: `:212-216` starts mid-sentence and drops the paragraph's
  opening line, and the no-matcher reasoning runs to `:226`, not `:222`.
  The "symbol, never line number" rule is scoped to `## Where to look`, which
  was clean — but its stated reason applies word for word here. (fixed — the
  prose cites the paragraph by its opening words instead.)
- r10: (verifier) the plan's one measured claim carried the when and no
  command, in a plan about a paragraph that was itself redded for a written
  number (`PR252 r3`). (fixed — the claim now names this session and its two
  artifacts, or is dropped where it cannot.)
- r11: (verifier) `## Review` held the literal `- (none yet)`, which `ci`
  counts twice (no id, no verdict) and `review` counts as one recorded
  finding — so the branch read as carrying a review record it did not carry.
  (fixed — replaced by these.)
- r12: (verifier) `## Traps` was mostly not Part 2 prohibitions but restatements
  of the plan's own direction and Out of scope. (fixed — the traps are the
  rules that bite: the naming rule itself, and the measured-number rule, for
  a plan whose implementer writes prose INTO the naming rule's own section.)
- r13: (verifier) the workstream file dispositioned none of the edge work
  `drain` ranks above the queue. (fixed — the disposition is recorded below,
  where the next session reads it.)

## Blockers

None. The plan's direction is proposed, not blocked: the requester holds the
veto and it is flagged in this session's report as well as in the plan's own
acceptance, which r5 is the finding for.

**Edge work, dispositioned** (Loop step 2, which `drain` ranks above the
queue): `origin/claude/multi-agent-orchestration-pr-jyli0w` names pull
request 10. Read from GitHub this session: `state: closed`, `merged: false`,
closed 2026-08-21. A closed, never-merged pull request is not edge work, so
it does not outrank the queue. Its branch is the human's to triage or delete;
a session never `git push --delete`.

## Where to look

- `.agents/docs/consumer-repos.md`, `## Name no consumer` — both paragraphs.
- `.agents/docs/glossary.md` — why `ci` cannot gate this one: the glossary
  fixes contested TERMS, and this is a contested rule about a class of
  reference.

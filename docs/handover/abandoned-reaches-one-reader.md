---
workstream: abandoned-reaches-one-reader
status: in-progress
branch: claude/abandoned-reaches-one-reader
pr: none
plan: none
issue: 279
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-10-07
next: Fold in the reader's findings, then retire this file and open the pull request
---

## Goal

Open issues outrank plans and `drain` does not read GitHub. Re-mapped after
PR #302 landed: #249, #251, #254/#257, #258, #267, #271 and #273 all have a
plan or an open question. **#279** (2026-09-17) is the oldest with neither.
Nothing builds unplanned, so decomposing it is this item.

Step 2's first clause is "Finishing outranks starting": the in-flight block
names no `pr:`-bearing entry that is unfinished — the one that did was released
at step 2 under an earlier drain item.

## Decisions

- **Every claim re-measured before planning; all five hold.** Unlike #258,
  whose central claim had gone false, #279's defects are live today:
  - §1, a release reds the branch it releases: **6 of 8** abandoned branches
    carry an enum without the word. Counted 2026-10-07 by
    `git show "origin/$b:joharness.sh" | grep -oE 'lint_enum "\$rel" status[^;]*'`
    over each. `worker-idle-detection-l3v9m3` knows it; the
    `multi-agent-orchestration` branch has a `joharness.sh` but no `status` lint
    in it, so nothing lints the word there.
  - §2, `cmd_graph` draws a released claim's `claims` edge:
    `awk '/^cmd_graph\(\)/,/^}/' joharness.sh | grep -c abandoned` → **0**, and
    `./joharness.sh graph | grep -c claims` → **7**, including
    `b_unsupervised_boundary`, `b_guard_docs_only_branch`,
    `b_marker_gate_needs_no_done` and `b_unsupervised_endurance`.
  - §3, the hook's row says `claims issue #230` while its own summary says no
    issue is claimed. Observed in THIS session's own session-start output.
  - §5 (from the comment, and the worst): `dispatch_curate_branches` honours
    the word nowhere — `sed -n '/^dispatch_curate_branches()/,/^}/p'
    joharness.sh | grep -c abandoned` → **0** — so releasing a curate claim
    does not free the cycle. It froze one for 18 days.
- **§4 is smaller than filed, and becomes a test rather than a plan.** The
  issue asks whether the STALE marker is load-bearing. It is — it feeds the
  sort key, not only the display (the sort at `handover-context.sh:780`, the field at `:617`). But the
  `abandoned` bracket already demotes those rows by rank 5 (`:469`), so the
  demotion survives. What is live is the consequence the issue names second:
  `./joharness.sh janitor` reads `none — every claim pushed inside 144h` while six
  of those claims are 485h old against a 144h gate — so they PASS the age gate
  and the `abandoned` test is what excludes them. The sentence is hardcoded
  (`joharness.sh:5406`) and I believed it; r3, r4 and #308. The case I thought
  was missing already exists in `selftest/janitor.sh`. §4's real content is r16:
  the independent git-derived evidence does NOT survive, and the issue itself
  leaves that as "may be acceptable as designed".
- **Two plans, split on kind, not on count.** §2, §3 and §5 are one-line
  filters in three readers, matching an idiom `queue-context.sh` already uses
  — one plan. §1 is not a reader to teach but a timing problem with three
  named options and a design choice between code and a sentence — its own
  plan, so the choice is visible rather than buried in a list of filters.
- **`cmd_janitor` DOES honour the word** (`joharness.sh:cmd_janitor`, the
  `[ "$status" = abandoned ] && continue` line), so it is named as the model
  the other readers should match, not as a defect.

## Rejected

- **One plan for all five.** §1's fix is a judgement between three options the
  issue lists; folding it in with four mechanical filters would let an
  implementer take the cheapest without the choice being seen.
- **A plan for §4.** Not because the harm is covered — r16 shows the
  independent evidence genuinely does not survive a returning session's
  `status: in-progress` — but because the issue itself leaves it as "may be
  acceptable as designed", and choosing for the requester is not a sweep's or a
  planner's call. Recorded in r16 for whoever decides.

## Review

- r1: (session, CORRECTED by r5) **I moved a selftest case to dodge a `curate`
  report, and the premise was false.** `curate` flagged my plan and
  `unowned-block-age` both claiming `.agents/harness/selftest/dispatch.sh`
  exclusively, and I relocated the case to `drain.sh` believing a proposal would
  make `curate : DUE` and so become the next session's top item. It cannot:
  `dispatch_curate_due` never reads the proposal count
  (`sed -n '/^dispatch_curate_due()/,/^}/p' joharness.sh | grep -cE 'propose'`
  → 0) and `cmd_drain` prints a curate line only when the cycle is `due` or
  `unreadable` — `./joharness.sh drain | grep -c curate` → 0 right now. The
  collision is real; its only consequence is `curate`'s own report, which is the
  backstop working as `.agents/docs/plans/README.md` describes. (fixed — the case
  is back in `dispatch.sh`, where it belongs, and the collision is DECLARED and
  flagged for the human rather than dodged: `curate`'s own words are "order them,
  or say they are one plan. The human decides".)
- r2: (session) **`ci` flagged BOTH plans `SHIPS to consumers` and only one had
  a consumer-side check.** `release-reds-the-branch-it-releases` touches
  `.claude/commands/janitor.md`, which ships, and all five of its Acceptance
  items were local. `.agents/docs/plans/README.md`: "A bar met only here is met
  in the one repo that was never the risk." Same defect as PR301 r4, one item
  later — and `ci` passes either way, so a green run was not evidence. (fixed —
  a sixth item names the consumer-side check: a consumer that synced the change
  sees a sweep's release note carry the sentence, and the returning session
  meets the red WITH the explanation. The consumer is where that red actually
  happens.)

- r3: (verifier) **the §4 selftest case I commissioned already exists, and my
  reason for it was false in the opposite direction.** It is in
  `.agents/harness/selftest/janitor.sh`: a positive control asserts the fixture
  IS a candidate, then it is rewritten `status: abandoned` and refuted. It passes
  today. And the reasoning — that age masks the filter, so a regression would be
  invisible for six days — inverts the facts: six abandoned claims are **485h**
  old against a 144h gate (`[ $((age * 60)) -ge "$stale_s" ] || continue`,
  `stale_s`=518400), so they PASS the age gate and are excluded one test later by
  `[ "$status" = abandoned ] && continue`. A filter regression would surface six
  candidates immediately. (fixed — the bullet is gone from the plan and the §4
  Decision below is rewritten.)
- r4: (session) **I believed a sentence the command never derived, and planned
  from it.** `./joharness.sh janitor` printed `none — every claim pushed inside
  144h` while those six claims were 485h old; the line at `joharness.sh:5406` is
  hardcoded and printed whatever emptied the list. That is #278's defect class —
  a reader asserting state it never read — in the command I spent this session
  fixing, and it cost this plan a wrong bullet. (filed as **#308**. Recorded here
  because the lesson is mine: the sentence was checkable in one command and I
  took it as a reading.)
- r5: (verifier) **the destination r1 chose disables the thing under test.**
  `.agents/harness/selftest/drain.sh` defines its helper with
  `JOHARNESS_CURATE_HOURS=0` hardcoded, which is the cycle's off switch, so the
  curate block is unreachable in that topic — its own header says so and names
  the home: `cuwork`/`trwork` in `dispatch.sh`. Worse, the control I said must
  stay untouched is driven by a helper that itself runs `./joharness.sh drain`,
  so my argument "the issue's evidence is `drain`" was already satisfied there.
  (fixed — the case goes in `dispatch.sh`, two lines from the existing fixture.)
- r6: (verifier) **Acceptance 3 was unsatisfiable.** `graph` draws an edge only
  for a claim naming a plan, and two of the eight abandoned claims carry
  `plan: none` — so the count falls by 6, not 8. (fixed — "abandoned claims
  naming a plan".)
- r7: (verifier) **wrong topic for the issue-row case, and a control it would
  have redded.** The dedicated topic is `handover-context-issue-claim.sh`, not
  `handover-context-rank.sh`, and a seventh fixture branch reds an assertion
  pinning the literal "and 4 more, ranked below these". (fixed — topic corrected
  in `scope:` and the count control named in Acceptance.)
- r8: (verifier) **"18 days" was this defect's wrong number.** The released
  status stood for **28 minutes** (claimed `1f3b08a` 2026-09-17 20:21:24,
  released `3792f07` 2026-10-05 22:47:37, retired `dbe4198` 23:15:54). The 18
  days were an ordinary `in-progress` claim, which this defect does not explain.
  (fixed — the plan now makes the issue's counterfactual argument, which needs no
  number: had the released session not returned, the cycle was frozen
  permanently.)
- r9: (verifier) **a false anchor.** `.agents/harness/selftest/janitor.sh` has no
  release-note cases — nothing in it reads `.claude/commands/`. I sent an
  implementer to extend a shape that does not exist. (fixed — the anchor now says
  the topic tests `cmd_janitor`'s output and the case is new.)
- r10: (verifier) **`needs:` was a fake edge that buried the issue's most
  important defect.** Plan B's deliverable concerns `lint_enum`'s enum, and plan
  A explicitly forbids touching any `lint_enum` call — so A's result cannot
  change B's sentence. The README is explicit that `needs` is for result
  dependencies only, and the cost is real: the hook lists a `needs`-blocked plan
  last and excludes it from the free list, so #279 §1 — which the issue calls
  "the one that matters" — would sit behind a `shared:joharness.sh` sibling.
  (fixed — edge removed.)
- r11: (verifier) **an attribution that is not in the record.** Both files said a
  PR294 reviewer "checked only the branch that knows the word and reasonably
  concluded the defect was inert". PR294's recorded review is 14 findings and
  none mentions the enum, `lint_enum` or #279; there are no reviews or comments
  on that pull request at all. The sentence carried weight — it made the defect
  look under-reviewed — and cannot be re-derived. (fixed — removed from both
  files. The 6-of-8 measurement stands on its own.)
- r12: (verifier) **both consumer-side acceptance items were self-certifying.**
  Each described a scenario, named no command, and ended with an escape hatch
  ("state whether it was run"). `TEMPLATE.md` asks for one check a consumer
  RUNS. (fixed — each names a command.)
- r13: (verifier) **plan B had no acceptance item that can fail informatively.**
  Items 3 and 4 were the same tautology twice — reverting or mutating the exact
  string an `expect` greps reds it by construction — and item 5 pinned output the
  plan cannot change, and was not even 0 on two branches. (fixed — rewritten, and
  the trap this shape already paid for is added: a case written from the sentence
  as typed rather than the wrapped line the file holds fails on the real file.)
- r14: (verifier) **`effort: medium` was the only sub-`high` effort in the
  queue**, on the one plan whose own Traps calls its target protocol text.
  `agent-selection.md` makes that an `xhigh` lever. (fixed — raised.)
- r15: (verifier) **three overstatements.** The `multi-agent-orchestration`
  branch DOES have a `joharness.sh` (328 lines) — what it lacks is a `status`
  lint, which is the true and sufficient reason. `handover-context.sh:554` is a
  comment, not the sort; the sort is at `:780` and the field at `:617`. And the
  hook's summary today says `#279 — this branch` and merely omits #230, rather
  than saying no issue is claimed. (fixed — all three.)
- r16: (verifier) **my §3 answer answered a different question than the issue
  asked.** I checked whether the demotion survives the age reset; rank 5 does.
  The issue asks whether the independent EVIDENCE survives, and it does not: rank
  5 is derived from the `status:` field, STALE from git. A returning session that
  sets `status: in-progress` — which the release note is required to invite —
  restores rank 3 with a fresh push age, so the branch reads as live current work
  with no git-derived contradiction, even if that session then dies. (fixed — the
  Rejected bullet now says this instead of "already covered by rank". Still not a
  plan: it is the issue's own open "may be acceptable as designed".)
- r17: (verifier) **plan A promised a single root fix that does not exist.** The
  three readers use three different frontmatter reads, so three tests is the
  honest answer; and `cmd_graph` cannot reuse `queue-context.sh`'s idiom (that
  one awks over a precomputed TSV). The shape to copy is `cmd_janitor`'s.
  (fixed — both corrected.)
- r18: (session) **I wrote a prediction about a tool instead of running it.**
  The plan said `curate` "will report two claims on one path as a PROPOSE". After
  marking the path `shared:` on this side, `./joharness.sh curate` reads `NOTHING
  TO CURATE — every declaration reads true` — so the prediction was false, and it
  also contradicts the belief r1 was built on, that a one-sided `shared:` marking
  cannot clear another plan's exclusive claim. For `curate`'s check it can.
  (fixed — the plan now states the measured output with the command. Recorded
  because this is the third time in one item I asserted a reader's behaviour
  without running it: r1's premise, r3's age reasoning, and this.)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_graph`, `joharness.sh:dispatch_curate_branches` — the two
  readers with zero occurrences of the word.
- `joharness.sh:cmd_janitor` — the reader that gets it right.
- `.agents/harness/queue-context.sh` — the filter idiom to match.
- `.agents/harness/handover-context.sh` — rank 5, and the row label that does
  not apply the test its own summary applies.

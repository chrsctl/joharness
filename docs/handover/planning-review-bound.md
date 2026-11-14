---
workstream: planning-review-bound
status: in-progress
branch: claude/trusting-goldberg-d7vuii
pr: none
plan: planning-review-bound
issue: none
session: https://claude.ai/code/session_01J1YMK3kUVqT3rMpf2mS888
agent: opus
updated: 2026-11-13
next: Retire plan and workstream, open PR, finish, merge; then sync to gx
---

## Goal

Cap the review on a planning pass and run its reviewers at opus; the human
chose levers A and B on 2026-11-13 after four gx planning passes cost ~$619.

## Decisions

- Money decision (tier below fable for planning reviewers) is the human's,
  given in this session 2026-11-13; a cap as a setting, also theirs.
- The cap sits on top of the per-plan 3-round bound and churn stop: the
  human asked for an upper limit, not a looser rule.

- Review churn on manager-reference.md (r18, r21, r23): research step, one
  rule for every requirement. An open finding must reach the build (r21),
  in the Assumptions shape (r24), so that refuted means fix (r23), with a
  record spelling (r25), and the plan and `review`'s line agree (r26, r29).
  Ran at the plan's own tier and effort (opus, high): neither raised.

- Planning manager effort xhigh to high: the human named the extra effort
  as a cost, 2026-11-14 (thinking was ~1M tokens a pass at fable output
  price). A looped session's "Run at effort xhigh" respawn stays.

- Default 12, not 25 (2026-11-14, the human left the number to this
  session: "well proven plans, but costs shouldn't explode"). 25 stopped
  none of the four measured passes (10, 11, 12, 21); 12 keeps the three
  that converged and stops the outlier. Per-plan 3 rounds, open findings as
  A<n> and the build's plan-check keep plans proven.

## Review

- r1: (verifier) review_planning_pass read the tree, so a pass adding a plan of the requirement's stem lost the opus tier (fixed: read at the merge base)
- r2: (verifier) "verifier spawns at opus" matched ws.md's line, passes without the fix (fixed: assertions read t.md's block only)
- r3: (verifier) bound replaced the per-plan 3 rounds and churn stop (fixed: the cap sits on top of both)
- r4: (verifier) review printed no plan-checker tier (fixed: the cap line names both)
- r5: (verifier) a build that deletes its base plan read as a planning pass (fixed: by r1; selftest case)
- r6: (verifier) agent-selection.md cost figures are not reproducible in this checkout (wontfix: billed modelUsage from the gx sessions' result events, outside any checkout; named in the line)
- r7: (verifier) Acceptance named no consumer-side check (fixed: plan Acceptance)
- r8: (verifier) doc said opus whatever the tier; a sonnet planning pass printed sonnet (fixed: doc says fable lowered to opus, a cheaper tier stays)
- r9: (verifier) the cap phrase broke across two lines, Acceptance grep could never match (fixed: one line, selftest checks the phrase)
- r10: (verifier) cap changed 10 to 25 with no evidence in the checkout (wontfix: the human's number, given in session 2026-11-13; Decisions)
- r11: (verifier) 0 printed "at most 0" (fixed: prints "no cap on review rounds", selftest case)
- r12: (verifier) round counts in orchestrated.md and agent-selection.md did not fit (fixed: per-branch counts from the sessions' subagent_stats, maxima named per branch)
- r13: (verifier) default 25 is above every measured pass (10, 11, 12, 21), so it caps none of them (fixed: default 12, Decisions)
- r14: (verifier) per-branch counts not checkable here (wontfix: billed gx sessions' subagent_stats, outside any checkout; invoicing-app's 11 is its verifier passes, its plan-checks fell in an earlier process)
- r15: (verifier) agent-selection.md said a planning pass's verifier is always opus (fixed: "at fable")
- r16: (verifier) no case held a cheaper planning pass at its tier (fixed: sonnet case)
- r17: (verifier) spawn prompt's base was the last-reviewed head, not the merge base (no change: agent-selection.md, Review depth, prescribes the parent of the fix commits for a follow-up pass)
- r18: (verifier) "a finding left open here is not lost" is false for a sonnet or haiku plan, which no build plan-check reads (fixed: says which plans are re-checked)
- r19: (verifier) a partly planned requirement whose open plan shares its stem is not read as a planning pass (wontfix: a plan wins a shared stem by design, joharness.sh "a plan wins a shared stem"; a planning claim cannot be told from that plan's build)
- r20: (verifier) no command counts rounds against the cap (wontfix: same shape as the per-plan 3-round bound, a rule the manager keeps; the human asked for a limit, not a gate)
- r21: (verifier) an open finding on a sonnet or haiku plan went to a PR body no build manager reads (fixed: it goes into the plan's ## Assumptions as an A<n>, which manager.md §2 has every build confirm)
- r22: (verifier) two lines stated the PR-body rule (fixed: one Open findings bullet)
- r23: (verifier) a finding written as an A<n> is confirmed true and nothing fixes the plan (fixed: the A<n> is the plan's own disputed claim, refuted = fix)
- r24: (verifier) no spelling for a finding as an assumption (fixed: the plans.md shape, confidence low)
- r25: (verifier) "left open" had no record verdict (fixed: wontfix: A<n> in <plan>, or wontfix: PR body)
- r26: (verifier) plan still said PR body (fixed)
- r27: (verifier) churn on manager-reference.md (fixed: research step recorded in Decisions, one rule replaces r18 and r21)
- r28: (verifier) spawn prompt's base was HEAD~1, not the merge base (no change: agent-selection.md, Review depth, prescribes the parent of the fix commits)
- r29: (verifier) review's planning line still sent open findings to the PR body (fixed: points at the Challenge rule; selftest refutes "PR body")
- r30: (verifier) research step left out review's line and named no tier (fixed: Decisions)
- r31: (verifier) knob row split the churn pair (fixed: moved after JOHARNESS_CHURN_LIMIT in both tables)
- r32: (verifier) r30's record claimed a raised effort; the plan already says opus/high, so nothing was raised (fixed: record says so)
- r33: (verifier) "routes open findings by the rule" passed on the phrase alone, not the pointer (fixed: expects the pointer line)

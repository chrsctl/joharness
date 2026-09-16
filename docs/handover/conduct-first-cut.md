---
workstream: conduct-first-cut
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: 251
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-16
next: Review the plan, retire this file, open the pull request
---

## Goal

Issue #251 asks for a periodic sampling review of a manager's CONDUCT — the
questions the verifier (which reads the diff) and the health pass (which
reads the pulse) structurally cannot answer. The issue ends by NOT claiming
the cost is worth it, and its shape is a session beyond the cap, which is
money.

Decomposing it is the work (Loop step 2). This branch adds one plan and no
code: the single conduct question that needs no session, no sampling, no cap
and no money, because it is answerable from git alone. The rest of #251 waits
on the cost decision, which is the human's.

## Decisions

- Deliver the PLAN, not the build. `.agents/docs/plans/README.md` names this
  shape: a pull request adding only the plan puts it in the queue. The build
  then goes to a session at the tier the plan sets, which is how an issue is
  supposed to reach code.
- The question picked is "were findings recorded BEFORE the fix and in the
  same commit", one of the five #251 lists. It is the only one decidable from
  commit order alone — no control-plane read, no second session, no sampling
  rate to calibrate, so none of the issue's own cost caveat applies to it.
- Chosen partly because this session BROKE it: finding r16 on the branch that
  merged as `#253` records findings written after their fixes and left
  uncommitted, caught by a verifier rather than by any gate. The rule has a
  live counter-example in this week's history.
- `ci` already carries two lints over this branch's findings — one report-only
  and one that reds — so the new one has a home, a pattern and a precedent
  for which strength to pick.

## Rejected

- Building the check on this branch. A lint that reds is a lint that can red
  somebody else's branch wrongly, and its false-positive shape (a wontfix
  touching nothing else, a fix legitimately split across commits) needs the
  design attention a plan exists to buy. Filing it as a plan is not deferral,
  it is the decomposition the Loop asks for.
- Taking #249's remainder. Its two halves are the scheduler, which is the
  human's, and the research node this session filed, which is queue work of
  its own and older-ranked behind the free plan.

## Review

- r8: (verifier) the plan's Traps and Acceptance contradicted each other on one shape: Traps called "a finding ALONE in a commit" the violation, Acceptance required a finding whose fix spans two commits to be exempt, and by Traps' wording that shape IS alone. Whoever built it had no way to know which section governed. (fixed — "alone" is now defined as no fix content in that commit, and both sections say it the same way)
- r9: (verifier) Scope's algorithm never read the disposition marker, so as literally scoped it would flag every workstream-only commit including the `(wontfix)` findings Acceptance requires it to exempt. (fixed — the marker read is in Scope with the reason)
- r10: (verifier) the plan SHIPS — `ci`'s ship-scope stage says so, because it touches `joharness.sh` — and its Acceptance named no consumer-side check, which `.agents/docs/plans/README.md` requires once that stage fires. The same rule this session graduated in `#246`. (fixed — a consumer-side check is named, with why the topic file cannot be it)
- r11: (verifier) the backtest bullet left `N` unbound and "most of them" undefined, so the implementing session had nothing to compare against. (fixed — the window is the value `feedback` already reads, two numbers are reported, and the bullet says what the number is FOR rather than inventing a bar)
- r12: (verifier) "Where to look" cited two lint functions, neither of which resolves which commit added an id, and missed `fb_fix_map`, which already keys on the stable id and carries this exact trap in its own comment. (fixed — it is now the first anchor, marked read-this-first, with the note that Scope's query was tested against the case its comment describes)
- r13: (verifier) the four out-of-scope questions were grouped blindly; peer divergence needs no session and no sampling rate, only judgement about whether two branches met the same rule. Grouping it with the costly three understated what could ship. (fixed — it is separated, with the distinction that actually applies to it)
- r14: (session) the plan was named for a rule half it explicitly does not check. A literal reader arriving at `findings-before-the-fix` expects order-checking that git cannot do. (fixed — renamed `findings-with-the-fix`)
- r1: (session) the plan's central mechanic did not work as written, and its motivating example would have passed it. Tested before review rather than asserted: `git log -G'^- r18:' -- <ws> | head -1` returns the RETIRE commit, not the adding one, because the newest match comes first and a retire deletes every finding line at once while touching the plan file beside it — so the naive query reports a commit that passes. `--reverse | head -1` is what finds the add. (fixed — the corrected query is in Scope with the trap named, and the retire case is now an acceptance bullet)
- r2: (session) worse, the rule's FIRST half is not checkable at all. Git records what landed in a commit, never the order the author typed it. The finding that motivated this plan, `r16` on the branch that merged as `#253`, was written after its fix and committed with it — it passes the same-commit test. A plan promising to enforce "before the fix" would have sent the implementing session after something git cannot see. (fixed — the Goal says so, Out of scope says why, and the lint is required to carry it in its own comment. The plan keeps its title for the rule it serves, and narrows what it claims to check)

## Blockers

None.

## Where to look

- `joharness.sh:lint_finding_ids` and `lint_finding_markers` — the two
  existing finding lints, and the report-versus-red precedent.

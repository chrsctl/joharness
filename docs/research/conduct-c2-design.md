---
research: conduct-c2-design
urgency: normal
agent: opus
effort: high
graduates: .claude/commands/conduct.md
---

## Question

Can conduct check, per sampled branch, that the selftest case the branch
added for a fix fails on the code before the fix, without false FINE or
false CONCERN, inside a bound one conduct run can afford?

## Echo

Loop step 5 says "Test for a fix must FAIL without it". Nothing checks it
after merge. Conduct could, as question C2, if it can run the changed case
alone on the pre-fix parent and read that case's own verdict. A plan is
built on this only if the answer is yes. Known traps from review:

- A whole-topic red gives a false FINE. Causes: another case changed, a
  runner fatal, a chained topic (`SELFTEST_CHAINS`), a helper missing on the
  parent.
- Several things give a false CONCERN:
  - the stem merged in two pull requests, so the parent already holds the fix;
  - a case reaches `skip()`;
  - a refactor, or a characterization test that is not a fix's test;
  - a new topic file the parent's runner does not list.
- There is no single-topic selector in `.agents/harness/selftest.sh`.
- The full suite measured 493 s (verifier, 2026-10-25, `time bash
  .agents/harness/selftest.sh`, this container).

## Sweep

goal-directed: complete when each trap above has a design that defeats it,
or is shown not to, and C2's cost per branch is measured.

## What would settle it

YES: a runner design that reports the changed case's own PASS or FAIL on
the parent. It gets the right verdict on fixtures for every trap above, and
one branch costs a measured time small enough for 3 per run.
NO: any trap with no design, or a cost per branch too high for 3 per run.
Either answer is a finding; NO graduates as "C2 is not checkable after
merge; keep the rule at the verifier".

## Method

Pending: the researching session fills it.

## Findings

Pending.

## Consequence for the queue

Pending. YES = a plan adding C2 to conduct (ledger column, verdict per
case, selector). NO = none.

## Verification

Pending: a second context checks the findings.

## Graduates to

`.claude/commands/conduct.md`: C2 would be conduct's question, or the
reason it is not.

---
requirement: defect-to-fix-loop
priority: normal
---

## Goal

Requester, 2026-10-23, after a consumer manager (gx `ui-adapt-verify`)
blocked on a red suite on its base branch and a human had to ask: *"we only
asked 'can we fix' and found a proper solution, can we [add] a role
workflow etc to joharness that does this."*

What the human's one question set off, by hand, in one session:

1. The manager's blocker (an agent-fixable defect outside its plan's
   scope) became a fix plan, built and merged.
2. The fix asked how the defect reached the base branch: it bisected the
   failure into the merging pull request and named the check that let it
   through. A missing consumer gate became a second plan in the consumer;
   a harness gap became a finding.
3. The harness finding was checked against what canonical had already
   decided, then filed as a report on canonical.
4. The blocked manager was woken and finished.

None of these steps needed a human decision. The harness should run that
loop without the question.

## Satisfied when

- A manager that finds agent-fixable work outside its plan's scope (a red
  suite on the base branch, a defect in code another plan owns) stops
  without a human: the work becomes an issue the clerk plans. The manager's
  item resumes on its own once the fix merges. No `human-review` label and
  no push to the human for that block.
- A plan born from such a defect carries, as acceptance, where the defect
  entered (the merge, by bisection or reasoning from history) and which
  check passed it. A check this repo owns is fixed or planned in the same
  pull request; a harness-owned one is recorded as a finding that
  `./joharness.sh upstream` reports.
- In a consumer repo, a merged edge whose `upstream` verdict is REPORT is
  filed on canonical without a human starting `/upstream-report`, at most
  once per edge. Before filing, the reporter reads canonical's settled
  research and pull requests on the same question: it files only what is
  new, or files nothing and says why.
- Every step above is visible in `./joharness.sh dispatch` and leaves its
  record in git. Harness commands still never call the GitHub API.

## Constraints

- Blocks that do need a human (money, credentials, product, interface,
  core path, conflict, hardware) keep today's path unchanged.
- The clerk's gates (author gate, `human-review` skip, scout gate) are not
  relaxed: a defect issue enters as an issue like any other.
- No core path edit (`./joharness.sh protocol-paths`) without a
  `human/<stem>` pull request.

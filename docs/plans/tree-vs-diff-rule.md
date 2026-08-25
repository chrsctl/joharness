---
plan: tree-vs-diff-rule
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .agents/docs/feedback.md, .agents/harness/AGENTS.md
---

## Goal

One defect class has now cost four merged edges, and every fix was local to
the command that had it. Counted from `./joharness.sh feedback`, oldest first:

- PR54 r13 — `cmd_graph` labels an in-flight branch from the workstream files
  in its TREE, so a branch shows as work it merely inherited.
- PR58 r8 — `upgrade` refused every sync branch cut from a base branch that
  had accreted a workstream file: it asked "is there a file", not "did this
  branch introduce one".
- PR60 — `cleanup` called an inherited live file stale and `--apply` DELETED
  it; `finish` in the same review returned green on a branch carrying a live
  claim.
- PR69 — the finish gate's own edge test, in the merged implementation's
  words: "Own files only — read from fin_adds_at, so another session's
  inherited file cannot put this branch at an edge it is not at. That was the
  first thing this gate got wrong, and it fired on the branch that built it."
- A second, parallel session building the same plan hit it independently in
  the same hour, the same way, and for the same reason: it copied the review
  gate's tree reading because the plan said to.

Same question every time: **does this branch OWN that file, or did it merely
inherit it from the base branch?** Five sessions asked it wrong, each fixed
its own caller, and none wrote the rule down. Two of those five were building
the same feature at the same time and each rediscovered it alone — the
clearest evidence available that the cost is paid per session, not per
caller. That is stage 4 of `.agents/docs/feedback.md` missing — recurrence is
the score, and this is the repo's highest-recurring class.

## Scope

- `.agents/docs/feedback.md` — the worked example: a branch inherits every
  file its base branch carries, so presence in the tree says nothing about
  the branch. Ownership is a DIFF against the merge-base. Name the four
  edges above so the rule carries its own evidence.
- `.agents/harness/AGENTS.md` — one caveman line where a session writing
  harness code will meet it, pointing at the doc. House style:
  `.agents/docs/caveman.md`.

## Out of scope

- **Re-auditing every caller.** The known ones are fixed. A sweep for the next
  is its own plan, and this one is about the rule, not the audit.
- **`cmd_graph`'s label (PR54 r13).** Has its own plan,
  `docs/plans/graph-inherited-workstream-label.md`. That plan fixes the sixth
  caller; this one writes the rule so there is no seventh. Neither blocks the
  other, and doing only the first leaves the pattern exactly as findable as it
  was — which is the argument this plan is making.

## Acceptance

- The rule states the test (diff against merge-base, not tree) and cites the
  four edges by PR number.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh feedback .agents/harness/selftest.sh` still reaches the
  PR58 finding, so the evidence stays checkable rather than copied.

## Where to look

- `joharness.sh:fin_adds_at` / `fin_strength` — the newest instance, and a
  comment that states the rule in one place already. Graduating it means
  moving that reasoning where the next author reads it BEFORE writing the
  caller.
- `joharness.sh:cl_inflight` — the same fix in `cleanup`, comment included.
- `.agents/docs/feedback.md` — the four stages; this plan is stage 4.

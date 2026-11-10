---
plan: plan-names-duplicate-issues
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/dispatch-park.sh, .agents/harness/selftest/feedback.sh, .agents/docs/plans.md, .agents/docs/plans/TEMPLATE.md, .agents/docs/orchestrated.md, .agents/docs/orchestrator-reference.md, .agents/docs/manager-reference.md, .claude/commands/clerk.md
---

## Goal

A manager parked `defect: #<n>` on a DUPLICATE issue never resumes: dispatch's
RESUME keys on a retired plan whose `issue:` is exactly `<n>`, and a plan names
one issue. chrsctl/gx, 2026-11-10: #1449 and #1450 were one defect; plan
`criteria-crm5920-collision` named `issue: 1449`, its PR #1456 closed both, ten
parks on #1449 got RESUME, `mgr/views-door-projection` parked on #1450 kept
printing `PARKED #1450 … waits for a plan naming #1450 to retire` on a green
base (RECHECK's clock alone moves it). The same split broke the DEFECT-BOUND
count (two parks on one issue): one park on each twin held nothing, and two
more managers spawned and parked. Harness commands never call the GitHub API,
so the fix must be readable from git.

Mechanism (decided here):

1. A plan's `issue:` may name several issues, comma-separated
   (`issue: 1449, 1450`): one defect filed twice is one plan. Every reader of a
   PLAN's `issue:` reads the list — `plan_names_issue` (RESUME and the
   `named` lift), `base_issues_prime`, `clerk_issue_nums` (`clerk` PLANNED),
   the plan lint. A workstream claim's `issue:` stays one number.
2. Retire-time rule (manager-reference § Plan issue): every issue the pull
   request closes is in the plan's `issue:` before the retire commit — the
   deleted plan's text is what RESUME reads, so a `Closes #1450` the plan
   does not name resumes nobody.
3. Clerk rule: an issue that is a duplicate of one a plan (or this pass)
   already takes is added to that plan's `issue:`, never planned twice.
4. Park-time rule (manager-reference § Defect): after filing, search once
   more; a lower-numbered open issue for the same failing command = the
   duplicate race: comment `duplicate of #M` on your own, park on #M. Parks
   then pool on one number, so DEFECT-BOUND counts them together.

## Scope

- `joharness.sh` — `issue_list_verdict` (new: list through `issue_verdict`
  each), `plan_names_issue`, `base_issues_prime`, `clerk_issue_nums`, the
  plan lint's `lint_issue` call.
- `.agents/harness/selftest/dispatch-park.sh` — a fix plan naming `21, 22`
  retires: a park on #22 RESUMEs; a plan naming `41, 42` on the base lifts
  DEFECT-BOUND for #42.
- `.agents/harness/selftest/feedback.sh` — `issue_list_verdict` cases.
- `.agents/docs/plans.md`, `.agents/docs/plans/TEMPLATE.md` — `issue` field
  takes a list.
- `.agents/docs/orchestrated.md` (The one stop),
  `.agents/docs/orchestrator-reference.md` (Resume) — "a plan naming #<n>"
  includes a list.
- `.agents/docs/manager-reference.md` — § Defect park-time twin search,
  § Plan issue retire rule and its `git grep` regex.
- `.claude/commands/clerk.md` — duplicate rule.

## Assumptions

- A1: RESUME reads the retired plan's `issue:` through `plan_names_issue` alone
  — evidence: `joharness.sh:dispatch_defect_state` — confidence: high
- A2: `named` reads base plans through `base_issues_prime` / `plan_names_issue`
  and DEFECT-BOUND keys on it — evidence: `joharness.sh:dispatch_defect_state`
  (`DEFECT_NAMED`) — confidence: medium
- A3: no other harness reader parses a plan's `issue:` — evidence: `grep -n
  "gr_field issue\|'^issue:'" joharness.sh` — confidence: medium

## Out of scope

- Reading closed issues or PR bodies: harness commands never call the GitHub
  API.
- Grouping parks on twin numbers dispatch cannot see in git (no plan yet):
  the park-time rule covers it.
- A multi-issue workstream claim `issue:`.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`, including the new dispatch-park cases:
  `PARKED #22 RESUME — the fix retired (fix2122)` printed, and DEFECT-BOUND
  absent once a base plan names `41, 42`.
- A test for the fix fails without it (run the new cases on `origin/main`'s
  `joharness.sh`).

## Where to look

- `joharness.sh:plan_names_issue` — the RESUME key.
- `joharness.sh:base_issues_prime` — base issue set.
- `joharness.sh:clerk_issue_nums` — clerk PLANNED list.
- `joharness.sh:issue_verdict` — the one format validator.
- `.agents/docs/manager-reference.md:## Defect` — park-time search.

## Traps

- Never call the GitHub API from a harness command.
- A test for a fix must FAIL without it.
- Never skip, disable or quarantine a test.

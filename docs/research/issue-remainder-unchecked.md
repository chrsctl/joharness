---
research: issue-remainder-unchecked
urgency: normal
agent: opus
effort: medium
graduates: .agents/docs/manager-reference.md
---

## Question

Do the harness's issue-closing rules state a fact they never measure, so an issue closes while work on it remains: by a manager PR that leaves part undone (`manager-reference.md` § Plan issue), or by a clerk's plan-only PR whose body carries a GitHub closing keyword (`clerk.md`)?

## Echo

The manager picks `Closes` or `Refs` by checking whether the plan file has a `## Issue remainder` heading. The clerk is meant to write that heading for a NARROWER verdict (`clerk.md` §3, "A plan without the section left no human remainder"), but nothing checks it does. If a clerk puts the deferred part somewhere else, for example in `## Out of scope` with "Record it in the PR body for a human", the manager writes `Closes #N`, and the issue's human question ends up only in a merged pull request body. Dispatch, the clerk and humans all look at open issues. Nobody looks at merged PR bodies.

## Sweep

Goal-directed: one consumer edge, plus the canonical files that hold the rule and anything that could enforce it.

## What would settle it

Yes: an edge whose plan defers an issue part to a human without `## Issue remainder`, whose PR wrote `Closes #N` and closed the issue as completed, and no canonical check (plan-checker, `ci`, `dispatch`, `queue-context.sh`) that reads plans for `## Issue remainder`. No: such a check exists, or the edge's plan carried the section.

## Method

Run in consumer `chrsctl/gx` on 2026-11-20, edge PR #1985 (merge `52a434cc`, branch `mgr-dockerfile-no-proxy-headers`, plan `dockerfile-no-proxy-headers`, `issue: 1966`):

```
./joharness.sh upstream 52a434cc
git show f0c48bace^:docs/plans/dockerfile-no-proxy-headers.md
issue_read #1966 get / get_labels          (GitHub MCP)
pull_request_read #1985 get                (GitHub MCP)
gh api -X GET search/issues -f q='repo:chrsctl/gx is:issue is:open trusted_proxies'
gh api -X GET search/issues -f q='repo:chrsctl/gx is:issue is:open X-Forwarded-For'
```

In a fresh canonical clone (`main`, depth 1, 2026-11-20):

```
grep -rln "remainder" .claude .agents joharness.sh
grep -n -i "remainder" joharness.sh .agents/harness/queue-context.sh .agents/docs/plans.md
grep -n -i "remainder\|out of scope" .claude/agents/plan-checker.md
```

## Findings

- **The edge's plan deferred one issue part to a human without the section.** The plan has `issue: 1966`, and its `## Out of scope` reads: "Making `Limits.trusted_proxies` configurable or enabling IP-range policy behind a proxy: the issue's second finding is a design decision (which proxies, which variable), not a defect fix here. Record it in the PR body for a human." The plan has no `## Issue remainder` heading (source: `git show f0c48bace^:docs/plans/dockerfile-no-proxy-headers.md`).
- **The manager followed the rule as written and closed the issue.** PR #1985's body opens `Closes #1966` and also says "**For a human (out of scope):** the issue's second finding … Not done here." Issue #1966 ended `state: closed`, `state_reason: completed`, `closed_by_pull_requests: #1985` (source: `issue_read`, `pull_request_read`).
- **The clerk's NARROWER visibility step was skipped too.** `clerk.md` §3 NARROWER says to apply `human-review` to the issue. `get_labels` on #1966 returned `{"labels":[],"totalCount":0}`.
- **Afterwards nothing tracked the remainder.** Both open-issue searches returned no items. A human noticed it by reading the PR body, and the consumer opened a new issue for it (chrsctl/gx#1991) by hand.
- **A second route to the same outcome: the remainder appears during the build.** I swept every gx PR merged 2026-11-06..2026-11-20 whose body says `Closes` (134 PRs) and grepped them for deferral wording. I also checked all 10 plans retired in that window that named an `issue:`. Only #1985's plan had the remainder under the wrong heading. Four more PRs closed their issue while their own body named an undone part of that same issue. None of those remainders could have been in the plan, because the manager or verifier found them while building. `## Issue remainder` is a heading the clerk writes, so it cannot catch these:
  - gx#1459 → #1384: "Backfill question (for a human, not built here)". Workflows that existed before the merge stay broken. Re-filed as gx#1992.
  - gx#1436 → #1353: "Open question (r5, not built)", a two-step version of the same disclosure. Re-filed as gx#1993 (security).
  - gx#1798 → #1775: "Not done (verifier r15)", against the issue's own done-when. Re-filed in gx#1994.
  - gx#1446 → #1369: "Not done … for follow-up", stale figures still in ADR 0168 and a phase spec. Re-filed in gx#1994.

  Before re-filing, a search of open issues found nothing for any of them (`gh api -X GET search/issues -f q='repo:chrsctl/gx is:issue <terms>'`). I excluded about a dozen hits whose "not done" text named a neighbouring defect rather than part of the closed issue. Rate: 5 of 134 `Closes` PRs in two weeks, 3 of them needing a human.
- **The opposite error: plan-only PRs close issues before any fix exists.** I swept the clerk's plan-only PRs in gx merged 2026-11-01..2026-11-20 (92 PRs with a `clerk`/`plan` title among the 632 merged; search API `is:pr is:merged merged:<range>`). 13 of them closed an issue. In every case the issue's `closed_at` is 1–2 s after the plan PR merged (search API `closed_at`):
  - 11 PRs from the 2026-11-10 batch (gx#1399–#1416). Their body line `Verifier (opus) findings, fixed: #<N> …` is parsed by GitHub as the closing keyword `fixed:`. The issues closed: #1360, 1362, 1365, 1369, 1373, 1374, 1377, 1380, 1383, 1388, 1390.
  - 2 PRs wrote the keyword deliberately, meaning it as future tense: gx#1342 "Closes #1341 when built", gx#1738 "Closes #1725 on build".

  Every one was later built by a manager PR (for example #1383 by gx#1606 two days later, #1388 by #1621, #1390 by #1627, three days later). So no work was lost here, but each issue read "completed" for hours to days while unfixed. Had a plan never been built, nothing open would have tracked the defect. gx#1924 (2026-11-19) wrote "Closes nothing: the plan's manager closes #1921", which suggests a session noticed. Canonical has no such rule: `grep -n -iE "closes nothing|closing keyword|fixed:|keyword" .claude/commands/clerk.md .agents/docs/*.md` hits only `manager-reference.md:328`, which is about something else. `clerk.md` says a plan's `issue:` is how the issue closes, but never says the clerk's own PR body must not carry a GitHub closing keyword (`close[sd]`, `fix(e[sd])`, `resolve[sd]`, with or without a colon) before an issue number.
- **Nothing in canonical measures the heading.** `grep -rln remainder` hits only prose docs and the *Human remainder* (core-path) mechanism in `joharness.sh:10589` and `queue-context.sh:690`, which is a different thing. `plan-checker.md` mentions neither `remainder` nor `out of scope` (empty grep). So `clerk.md`'s "A plan without the section left no human remainder" is an assumption that nothing checks.

Cost: about 10 minutes of a session and one hand-filed issue. The silent failure is the real cost: had nobody read the PR body, the IP-range defect would have had no open record.

## Consequence for the queue

Candidates for canonical to choose from. This report does not choose.
1. `manager-reference.md` § Plan issue: decide `Closes` vs `Refs` at PR open, from the PR body and the workstream file's `## Review` (`wontfix`, not built, for a human), not only from the plan's heading. Any undone part of the issue → `Refs #N` plus the § Link the issue comment naming it, or a new issue filed and linked. Of the two routes, only this option covers the build-time one (4 of 5 cases).
2. `plan-checker.md`: a plan with `issue:` whose `## Out of scope` defers part of that issue, but which has no `## Issue remainder`, is a defect.
3. A mechanical check in `ci` / `dispatch` would need a marker for "deferred to a human", and none exists today. Lower value.
4. For the plan-only finding: `clerk.md` says the clerk's PR body names issues with `Refs #N` only, and never puts a closing keyword (including `fixed:` in a verifier summary) before `#N`. A cheap check would grep a plan-only PR body before `merge_pull_request`.

## Verification

Not yet verified from an independent context. The facts above are direct tool outputs (GROUNDED on the commands listed). The claim that "no check reads it" is GROUNDED only for the files grepped.

## Graduates to

`.agents/docs/manager-reference.md`, because it holds the rule that turns the heading's absence into `Closes`; and `.claude/commands/clerk.md` for the plan-only finding. `.claude/agents/plan-checker.md` too, if canonical picks option 2.

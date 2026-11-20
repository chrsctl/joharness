---
research: issue-remainder-unchecked
urgency: normal
agent: opus
effort: medium
graduates: .agents/docs/manager-reference.md
---

## Question

Does the `Closes #N` / `Refs #N` rule in `manager-reference.md` § Plan issue state a fact ("the plan left no human remainder") that it never measures, so a plan that defers part of its issue to a human under another heading closes that issue?

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
- **Nothing in canonical measures the heading.** `grep -rln remainder` hits only prose docs and the *Human remainder* (core-path) mechanism in `joharness.sh:10589` and `queue-context.sh:690`, which is a different thing. `plan-checker.md` mentions neither `remainder` nor `out of scope` (empty grep). So `clerk.md`'s "A plan without the section left no human remainder" is an assumption that nothing checks.

Cost: about 10 minutes of a session and one hand-filed issue. The silent failure is the real cost: had nobody read the PR body, the IP-range defect would have had no open record.

## Consequence for the queue

Candidates for canonical to choose from. This report does not choose.
1. `manager-reference.md` § Plan issue: before writing `Closes #N`, the manager also checks its own PR body and `## Out of scope` for any part deferred to a human. If one exists, write `Refs #N` and add a comment on the issue naming the open part.
2. `plan-checker.md`: a plan with `issue:` whose `## Out of scope` defers part of that issue, but which has no `## Issue remainder`, is a defect.
3. A mechanical check in `ci` / `dispatch` would need a marker for "deferred to a human", and none exists today. Lower value.

## Verification

Not yet verified from an independent context. The facts above are direct tool outputs (GROUNDED on the commands listed). The claim that "no check reads it" is GROUNDED only for the files grepped.

## Graduates to

`.agents/docs/manager-reference.md`, because it holds the rule that turns the heading's absence into `Closes`. `.claude/agents/plan-checker.md` too, if canonical picks option 2.

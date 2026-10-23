---
research: local-checks-consumer-command
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/consumer-repos.md
---

## Question

Under `JOHARNESS_CHECKS=local`, should `finish` run a command the consumer
declares (its own loop, scoped by the consumer to what it can afford) and be
red on its exit, given that today it runs none of the consumer's checks, not
even the free loop the consumer's AGENTS.md makes mandatory?

## Echo

#513 settled "local mode leaves CI-only suites run by nothing" as YES and
kept local mode's behaviour. It rejected three mechanisms: `finish` naming
each unrun job, a patrol role, and running CI-only suites from `finish` on
every merge (rejected on runtime). This node asks a narrower question that
none of the three covers. In local mode, the merge gate is `finish`, and
`finish` runs only `ci` (+ `verify`). The consumer's own loop
(`run-all.sh` in gx, about 25 s, free and offline) is gated by prose alone,
and so is any heavier check the consumer is willing to pay for on the paths
it chooses. The harness gives a consumer no way to put its own command
behind the `pass` verdict. What rests on the answer: whether a consumer's
"must pass before merge" can be mechanical in local mode, or only a rule
line a session can forget after its last commit.

## Sweep

goal-directed: one consumer (chrsctl/gx), two merged defects and the gate
code that let them through. Enough to show the gap is the gate, not the
sessions.

## What would settle it

- YES: a consumer merge under `finish: pass` in local mode whose own
  declared pre-merge check was red at the merged head, where the consumer
  could have run that check at merge time for an affordable cost.
- NO: `finish` already runs a consumer-declared command, or every such
  defect needed a suite the consumer could not run locally at merge.

## Method

In chrsctl/gx, 2026-10-23:

```
node platform/web/storyboard/audit.mjs --scene dashboards-header   # at each first-parent merge since #785, and along #785's branch
cd platform/web && node storyboard/selftest.mjs                     # on origin/main 5f971a905
mcp github pull_request_read get_check_runs 785 / 812
grep -n 'joharness.sh" ci\|joharness.sh" verify' joharness.sh      # canonical, checks_gate
```

## Findings

- **`finish` in local mode runs no consumer command.** `checks_gate` runs
  `"${ROOT}/joharness.sh" ci`, then `verify` when `checks_verify_needed`
  holds, then prints "Not covered here". There is no hook, conf key or
  path through which a consumer's loop runs. gx's AGENTS.md says
  `bash run-all.sh` "must pass before any change is done", and
  `audit.mjs`/`contrast.py` must be green "before any UI change is done".
  Nothing at merge time checks either.
- **#785 merged with `audit.mjs` red, under `finish: pass`.** The audit
  passed 13/13 at `96f320878` (the branch's last merge from main) and
  failed 0/3 at `cac0a938d`, the branch's own "verifier findings r1-r6"
  commit (it rewired a control to a panel making an unrecorded request).
  Every check run on #785's head concluded `failure` in 2 s (no runner).
  Main stayed red seven days. A later manager (gx `ui-adapt-verify`) found
  it, filed gx#806 and blocked on a human. The fix needed a separate plan,
  a session, and a re-record needing Postgres 18, MinIO and a browser
  (gx#812).
- **A second suite was red on main at the same time, unnoticed.**
  `storyboard-test` reported 358/370 on `5f971a905`. Eight of the
  failures were scenes no #806 work touched (gx#811), merged under
  `finish: pass` after 2026-10-15.
- **The cost is the consumer's to scope, and it scoped it.** gx's web
  checks take 439 s + 427 s (4-core container, 2026-10-23), too heavy for
  every merge. gx#820 merged `scripts/web-checks.sh`, which runs them only
  when the branch touches `platform/web/` and prints "not required" in
  under a second otherwise. gx's AGENTS.md now names it in Loop step 5.
  Run on #785's head (`7e5819988`), it fails and names the scene #806 was
  about. This answers #513's runtime objection for this consumer. It still
  gates nothing at merge, because `finish` cannot call it: step 5 is prose,
  and #785 shows a session stopping one commit short of re-running it.
- **What fixing the misses cost.** gx#812 (re-record, about 25 min of
  recorder plus Postgres 18 and MinIO setup), gx#820 (the script plus one
  scene row), and a new urgent gx plan for the scene a re-record cannot fix.
  That scene's first transcript was hand-made and has been red since a
  genuine re-record on 2026-10-15, unnoticed until 2026-10-23.

## Consequence for the queue

Canonical decides. The smallest change the findings point to: a
consumer-owned declaration (a file outside the protocol paths, such as
`.agents/local-checks`, or an environment key beside `JOHARNESS_CHECKS`)
naming one command. `finish` in local mode runs it after `ci`/`verify`,
shows its last line, and is red on non-zero. With no declaration,
behaviour is as today, plus "Not covered here" saying no consumer command
is declared. The consumer bears the runtime and the scoping, so the
runtime objection in #513 does not transfer. Naming jobs and the patrol
stay rejected; this proposes neither.

`.agents/docs/consumer-repos.md` § Local checks graduates the answer.
`joharness.sh:checks_gate` is where it lands if YES.

## Verification

Not yet verified by a second context in canonical. In gx a verifier
(sonnet) reviewed gx#820 and found no way for a failing suite to give a
green verdict. Each finding names its command and
commit and is re-countable in chrsctl/gx.

## Graduates to

`.agents/docs/consumer-repos.md` § Local checks: it states the status quo
this node challenges ("`ci` runs the harness's own checks, never a
consumer's suites").

This is a report from a consumer (chrsctl/gx). Canonical decides whether and
how to act.

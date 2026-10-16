---
research: local-checks-skip-ci-only-suites
urgency: normal
agent: opus
effort: high
graduates: .agents/harness/AGENTS.md
---

## Question

Does `JOHARNESS_CHECKS=local` state a fact it does not measure: that
`finish` "runs this head's checks itself", when a consumer's suites that
only GitHub CI runs are then run by nothing, and nothing in the harness
notices or routes their failures to the queue?

## Echo

A consumer switches to local checks because Actions cannot allocate a
runner. The harness then gates merges on `ci` + `verify` (+ the consumer's
free loop). Any suite the consumer deliberately keeps OUT of the free loop
and gives to CI (gx: the CRM suites, which need Postgres and a browser,
ADR 0039 in gx) silently stops being run. Merges keep landing, the suites'
criteria keep being counted as established, and regressions accumulate
until a human happens to ask. What rests on the answer: whether local mode
is a safe posture for weeks, or needs a mechanism that captures and queues
what CI used to catch.

## Sweep

goal-directed: what one consumer (chrsctl/gx) measured while in local mode,
enough to decide whether the harness owes a mechanism. Canonical decides
which.

## What would settle it

- Settled YES: a consumer in local mode merged changes that broke CI-only
  suites, and no harness role (finish, clerk, orchestrator, steward)
  detected or queued them.
- Settled NO: some existing role runs or reads those suites in local mode,
  or the regressions were caught and queued without a human asking.

## Method

On chrsctl/gx, 2026-10-16, in a cloud session:

- GitHub API, `list_workflow_runs` on `ci.yml`: last `conclusion: success`
  is run 873 (2026-09-07); every run since (to run 1965, 2026-10-16
  19:23Z) fails in 2-7s, jobs with no steps, no runner, logs 404.
- gx `joharness.conf`: `JOHARNESS_CHECKS=local` set 2026-09-16, with a
  comment naming the billing annotation; still set.
- Ran gx's `crm` job by hand on `origin/main` (a2ad3eb1, then 29d0dba8):
  each suite in the workflow's order on a fresh Postgres 18 UTF8 database,
  `moto_server` for the S3 store (no Docker), no Gotenberg.
- `list_issues` on gx: what had been reported, by whom.

## Findings

- **Ten regressions sat on gx main, merged under `finish: pass`, with no
  harness role reporting any.** All were found by the hand run on
  2026-10-16, after the human asked "can we just run in here":
  - CRM1665 (`api.py`): a substring test for `"note"` matched a column a
    later commit (3e61bf9ec, is24) added. Red on every branch deployment.
  - CRM177/CRM341/CRM895 (`public.py`, `channels.py`): a function-level
    import in `api/suggest.py` (24889050f, 2026-10-12) put the model
    adapter in the public and ingress doors' import closure — a security
    bound (gx ADR 0059/0209), not a style check.
  - CRM713 (`agent.py`): agent grounding omitted the `archived` flag the
    metadata door added (b4443a83d, 2026-10-15) — a real product gap.
  - CRM212 (`sessions.py`), `quotas.py`, `messages.py` ×2, `channels.py`
    (connection-module bound): assertions the code had moved past
    (0824329a7 aliases, 7f08b40ca save_record, ADR 0254 realtime, ADR 0227
    gotenberg, f6f3ef628 `$me`) — one crashed its suite.
  - `web.py`: one merged test (gx #788) stranded its own scene and left
    about 200 browser criteria unmeasured; a race in another
    (`ledger-and-queue.mjs:1426`, `Route is already handled`) ended the
    whole browser half on 2 of 3 runs.
  Fixes: gx PRs #791 and `fix-crm1665-table-names`.
- **The only prior reports were incidental, and the queue's check of one
  missed what it was about.** gx#358 (2026-09-12) was filed unasked by a
  session that happened to reproduce the `crm` job for a harness sync; it
  wrote "while Actions is down, nothing else will notice". The clerk read
  it on 2026-10-13 and commented DOES NOT HOLD after running only the
  database-free storyboard suite — stating that it did not run `web.py`
  because it had no Postgres. At least two of the regressions above were
  already on main then.
- **`tools/criteria/index.py` in gx kept counting the CRM criteria as
  established-by-CI** throughout, because it checks that the workflow
  invokes each suite (gx#176, gx#282), not that a run passed. Local mode
  makes that claim unconditionally false and nothing says so.
- **The cost of running them is known and bounded here.** The full `crm`
  job ran in a cloud container in ~35 min sequentially (`api.py` 432s,
  `web.py` ~18 min); everything but the PDF renderer and a real MinIO is
  installable without Docker (gx `scripts/crm-pg18.sh`, `crm-deps.sh`).

## Consequence for the queue

Canonical decides. The gap the findings show: in `JOHARNESS_CHECKS=local`,
the harness has a fixing half (clerk -> plans -> managers) but no capturing
half for CI-only suites. Shapes a session here considered, none chosen:
a consumer-declared "CI-only suite" command that `finish` runs when a diff
touches its paths; a clock-driven role that runs it on the base branch and
files one issue per newly failing criterion for the clerk; or `finish`
stating, per head, which consumer suites it did NOT run, so the claim is
true. The graduating file is the step-7 line in
`.agents/harness/AGENTS.md` that defines what local mode verifies.

## Verification

Each finding above names its commit or command; the gx fix PR records the
before/after counts per suite.

This is a report from a consumer (chrsctl/gx). Canonical decides whether
and how to act.

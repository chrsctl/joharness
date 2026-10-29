---
research: parked-pr-merge-stalls-fleet
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/manager-reference.md
---

## Question

Does a `defect:` park leave an open pull request that a person can merge
with its workstream file on the head, and once `main` turns red that way,
does any role plan the fix before `JOHARNESS_DEFECT_PLAN_HOURS` runs out?

## Echo

On 2026-10-29 in chrsctl/gx, five open pull requests in a row went
unmerged for about five hours, and seven managers parked on one defect.
That defect was a two-file deletion. If parking leaves a pull request that
can be merged, and no role can plan the red that merge causes, the stall
will happen again on any consumer whose GitHub checks give no signal.

## Sweep

`goal-directed`: this follows one incident's chain through the gx history,
the gx issues and the session records. It is not a survey of every park
path.

## What would settle it

- **Yes:** a parked head that carries `docs/handover/<w>.md` merged through
  GitHub, and `main` went red on the ledger check. No clerk planned the
  `blocking:` defect it filed until something outside the queue fixed it.
- **No:** the merge needed a step the park forbids, or a clerk or manager
  was dispatched for the defect inside the window.

## Method

```
# in chrsctl/gx
git log --format='%h %ci %s' -4 5a8f5d0f8          # PR #1092 head
git log --format='%h %ci %s' -3 aef4e8f94^2        # PR #1090 head
git log --format='%h %an|%cn %ci %s' --merges --since='2026-10-29 12:00' --until='2026-10-29 12:20' origin/main
python3 tools/handover/ledger.py                    # on origin/main 01bd64981
```

GitHub MCP: `issue_read #1101`, `pull_request_read #1105 get_check_runs`.
claude-code-remote: `list_sessions` and `list_events` for the clerk and
orchestrator sessions of 2026-10-29.

## Findings

- **A park after the retire commit puts the workstream file back on an
  open, non-draft, unlabelled pull request.** GitHub merges that pull
  request, and `main` goes red for every branch.
  - PR #1092's head: `4367bf2d1 Retire storyboard-check-in-sharded-pass`
    (10:56Z), then `5a8f5d0f8 park storyboard-check-in-sharded-pass: finish
    blocked on #1095, #1065, #1085` (11:26Z).
  - PR #1090's head: `58181e171 Retire audit-office-scene-names` (10:44Z),
    then `ea37ffb5f Block audit-office-scene-names on defect #1065`
    (11:43Z).
  - Both merged by hand through GitHub: `aef4e8f94` at 12:12:55Z and
    `01bd64981` at 12:13:09Z, committer `GitHub`. The session behind #1096,
    merged at 12:08Z, recorded "merged by someone else, not the agent".
  - Then `tools/handover/ledger.py` on `01bd64981` printed `[FAIL] every
    workstream file names a branch that is NOT yet in origin/main`, with
    `MERGED but still listed: audit-office-scene-names.md,
    storyboard-check-in-sharded-pass.md`.
  - The consumer's `local-check` runs `run-all.sh`, so `finish` was red on
    every branch from then on.
  - Nothing on GitHub warned against the merge. Every Actions job on this
    consumer fails before any step runs: PR #1105's 6 check runs completed
    `failure` in about 2s each, and `get_job_logs` returns 404. Under
    `JOHARNESS_CHECKS=local` the merge button sees all red, all the time.
  - Today, `manager-reference.md` § Defect says the opposite:
    "**Park** = … push, exit. No `human-review` on the pull request".
- **The clerk cannot plan a `blocking:` defect when its own pull request is
  blocked by that same red.** Its "at most one in flight" then holds the
  cycle for `JOHARNESS_CLERK_STALE_HOURS` (24h).
  - Timeline:
    - The 12:20Z clerk opened PR #1100 and ended with "merge blocked by
      finish check on merged-branch handover docs".
    - #1101 (`defect: tools/handover/ledger.py: MERGED but still
      listed…`) was filed at 13:03:12Z, its body opening `blocking:`.
    - No clerk session ran between 12:36Z and 17:29Z.
  - The orchestrator's ledger at 15:45Z read `clerked=2026-10-29T1220Z`,
    with seven items `next=defect parked 1101`.
  - Its 16:11Z handoff said: "seven of those wait on one defect, #1101.
    That defect needs a plan to fix it, so it will keep the fleet stuck
    until one lands". The pass before had said "which I can't take on in
    this role".
  - `JOHARNESS_DEFECT_PLAN_HOURS` = 48, so `PARKED #1101 UNPLANNED` would
    not have reached a human for two days.
  - The fix came from outside the queue, in an ad-hoc session the user
    started: PR #1107 at 17:27Z, which deletes the two files. That was
    4h24m after filing, and `run-all.sh` went 28/29 → 29/29.
- **The orchestrator kept spawning managers onto a `main` it already knew
  was red.**
  - At 15:45Z, with five items parked on #1101, it spawned
    `crm-cb16-deal-list-views` and `pm-plugin-view-count-sixteen`.
  - Both parked on #1101 by 16:00Z, and their session summaries name it.

Dropped: 1. `upstream storyboard-check-in-sharded-pass` placed its r6 on
`SKILL.md`, but that is the consumer's own storyboard skill, not a file
canonical owns. The other 17 review findings were on consumer files or
were unplaceable.

## Consequence for the queue

These are consumer observations, and canonical decides. Candidate changes:

1. **`manager-reference.md` § Defect (Park), with `handover.md`.** A park
   on a head with an open pull request makes that pull request a draft
   (`update_pull_request draft: true`), and the resume un-drafts it at
   step 7. GitHub refuses to merge a draft, so a parked head stays
   unmergeable even when checks give no signal. Alternatively, `finish`
   could refuse to treat a head as mergeable when it carries a workstream
   file whose `status:` is not `done`, but that does not stop the merge
   button.
2. **`clerk.md` §1 / `joharness.sh:cmd_clerk`.** A clerk pull request whose
   only red is a parked `blocking:` defect would not hold the cycle. Or an
   unplanned `blocking:` defect would call a clerk whatever is in flight,
   the way `JOHARNESS_ISSUE_CLERK_HOURS` calls one early.
3. **`orchestrator.md` / dispatch.** When N parked managers share one
   unplanned `blocking:` defect, dispatch would hold new spawns that would
   hit it. It would also offer a fast-lane manager (`plans.md` Fast lane)
   for a defect that is mechanical: the ledger names the exact files.
   `JOHARNESS_DEFECT_PLAN_HOURS` (48) could be lowered when two or more
   managers park on the same issue.

## Verification

None yet. Canonical's reader checks each finding against the gx history
named in Method.

## Graduates to

`.agents/docs/manager-reference.md`: the park step is where the mergeable
head is made. Clerk and dispatch cadence follow from it.

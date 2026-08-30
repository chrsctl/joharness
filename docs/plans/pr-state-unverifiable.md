---
plan: pr-state-unverifiable
urgency: urgent
agent: sonnet
effort: low
needs: none
requirement: none
scope: .agents/harness/handover-context.sh, .agents/harness/selftest
---

## Goal

The session-start hook asserts a fact it cannot check, at the top of the
queue, where it outranks every other decision a session makes.

`handover-context.sh` reads `pr:` out of a workstream file and prints

```
EDGE: pull request #10 open — drive it green, then merge (step 7)
```

The hook reads git and never GitHub, so "open" is not something it knows.
PR 10 has been **closed, unmerged, since 2026-08-21** (`closed_at`
2026-08-21T20:19:09Z, read from the GitHub API on 2026-08-30). Its session
went idle needing a human — its own last recorded state is "awaiting merge
order (#8 -> #7 -> #5) before #10" — and nothing has moved since.

For nine days every session on this repo has been told, first thing, that
its highest-ranked duty is to drive a closed pull request to green on a
branch 679 commits behind `main`. Step 2 says finishing outranks starting,
so the cost of a false edge is not a stray line: it is the whole queue,
misread, from the first prompt.

## Scope

- `.agents/harness/handover-context.sh`: the rank-2 `EDGE:` line and the
  matching `lead_why`. Say what the hook actually knows — the workstream
  file NAMES pull request N — and tell the reader to verify the state before
  driving it, naming why the hook cannot.
- `.agents/harness/selftest/handover-context-rank.sh`: the two cases pinning
  the old wording move with it, and one new case asserts the hook never
  claims a state it cannot read.

## Out of scope

- **Asking GitHub.** This is a session-start hook: it must run offline, and
  it is already 411 of a 700 budget. A network call at the top of every
  session buys one fact and costs every session that has no network.
- **Changing the rank.** A closed pull request and an open one are the same
  bytes to git, so rank 2 stays where it is. The fix is the claim, not the
  order — and the STALE line already fires on this entry.
- Anything about branch deletion or closing the pull request. A session
  never pushes a branch delete, and retiring somebody's closed pull request
  is a human's call.

## Acceptance

```
bash .agents/harness/selftest.sh    # 0 failed
./joharness.sh ci                   # ci: pass
./joharness.sh session-start        # the rank-2 entry claims no state
```

The new case must red when the old wording is put back — put it back, run
the suite, then restore. Green both ways pins nothing.

Consumer-side, because the hook ships: in a synced repo carrying a
workstream file with a `pr:` field, `./joharness.sh session-start` must
describe that pull request without asserting it is open.

## Where to look

- `.agents/harness/handover-context.sh` — the `case "$rank"` that writes
  `EDGE:`, and the `case "$rank"` that writes `lead_why`.
- `.agents/harness/selftest/handover-context-rank.sh` — "an open pull
  request is an edge", "work still building is not an edge".

## Traps

- The `EDGE: pull request #none` refutation works by matching a string the
  code cannot produce for an unset `pr`. Reword the line and that refutation
  can go vacuous — green because the needle no longer exists in any state.
  Re-point it at the new wording and check it reds when rank 2 is wrongly
  given to an entry with no `pr`.
- Caveman house style: this file's lines are read at every session start.

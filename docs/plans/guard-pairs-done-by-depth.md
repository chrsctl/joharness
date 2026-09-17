---
plan: guard-pairs-done-by-depth
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: .agents/harness/pretool-bash-guard.sh, .agents/harness/selftest/pretool-bash-guard.sh, docs/research/bash-guard-reads-prose-as-a-loop.md
---

## Goal

Issue #271. The guard walks a command one loop at a time and takes the FIRST
`done` as the end of the loop it just found. Nest anything that carries its
own `done` ahead of the sleep and the walk judges a truncated body, finds no
`sleep` in it, and moves past the real loop without ever judging that.

Two payloads, both ALLOWED, measured in this checkout on 2026-09-17 (the
runner is in Acceptance):

```
exit=0  until grep -q x /tmp/f; do for y in 1 2; do : ; done; sleep 20; done
exit=0  i=0; while [ $i -lt 3 ]; do until grep -q x /tmp/f; do sleep 20; done; i=$((i+1)); done
```

The first is the issue's. The second was found writing this plan and is the
worse of the two: the inner wait is unbounded, the counter that lets it
through belongs to a DIFFERENT loop, and "a counter in a harmless loop reads
as bounding a dangerous one" is the exact defect the walk exists to prevent
— it was never prevented at depth. Both are pre-existing: both ALLOWED on
the guard as it stood before #270 (`31064b7`) as well, so that change neither
introduced nor fixed either.

This is the fix `docs/research/bash-guard-reads-prose-as-a-loop.md` names in
its `## Consequence`, and building it is that node's graduation. The node is
answered — which keyword owns this `done` and which `done` closes this
keyword are ONE defect, pairing positionally, and a narrowing at either end
opens the other, measured and reverted there. What is not settled is the
fix, which is why the node stays open and why this plan carries no
`research:` edge: that edge blocks a plan while the node exists, and this is
the one plan whose merge deletes it.

## Scope

- `.agents/harness/pretool-bash-guard.sh` — replace the end-finding step in
  the walk. Walk forward from the keyword counting `do` up and `done` down;
  the `done` that returns the count to zero is this loop's own. The walk
  already does prefix arithmetic with `${rest%%"$seg"*}`, so this is the
  same style, and it REPLACES the two lines rather than adding a clause
  beside them.

  Two properties the current walk has and the rewrite must keep. It
  terminates — `rest` loses at least the keyword on every pass, and that is
  the one property this file has no business getting wrong. And it fails
  open: a command whose depth never returns to zero is a shape this reader
  cannot understand, so it allows and says nothing, exactly as a malformed
  payload does.

  An inner loop must still be judged on its own. Whatever the span is used
  for, a `while` or `until` nested inside it cannot become invisible — that
  is the second payload above, and a rewrite that consumes the whole span
  and resumes after it reintroduces it in a new place.

- `.agents/harness/pretool-bash-guard.sh`, the `sleep` test — decide, and
  record the decision in the file's own comment, whether `sleep` is looked
  for in the whole span from keyword to the depth-zero `done` or only in
  text belonging to this loop. The issue asks for it to be weighed here
  because it is the same bug read from the other end: a `sleep` inside a
  nested `for` is still a sleep the outer loop performs every iteration.

  The counter tests are not the same question and the answer for `sleep`
  does not carry to them. `count_re` and `arith_re` decide that a loop is
  BOUNDED, so reading them over a span that contains other loops is how the
  second payload got through in the first place. Whatever is decided for
  `sleep`, a counter may only bound the loop it belongs to.

- `.agents/harness/selftest/pretool-bash-guard.sh` — a case for each payload
  in Goal, plus the two shapes the reverted attempt broke, which no case
  covered at the time and which green `ci` said nothing about:

  ```
  until docker compose logs db 2>&1 | grep -q "ready for connections"; do sleep 5; done
  until grep -q "ready for merge" /tmp/out; do sleep 20; done
  ```

  Both are denied today (exit 2, same run as Goal); they are cases because
  the last change here made them pass and nothing noticed.

- `docs/research/bash-guard-reads-prose-as-a-loop.md` — deleted by this
  plan's pull request, and its reasoning carried into the guard's header
  comment, which is what its `graduates:` names. Not a rule line: the
  why-explanation is what stops the next session re-opening a settled
  question, and this harness keeps no superseded record. What has to survive
  is that the two ends are one defect and that a clause at either end opens
  the other, with the reverted attempt's measurements.

## Out of scope

- Adding one more test beside the end-finding step. The node's `##
  Consequence` forbids exactly that, having built it and reverted it.
- Putting `for` into `start_re`. Measured in the node: the word `for` inside
  a loop's own condition then skips the keyword and nothing restarts the
  walk, and `"ready for connections"` is a real readiness line in the layer
  this repo selects.
- Making the guard parse shell, or reaching for `bash -n`, `grep` or any
  other external command. The perf row budgets this hook at 0 external
  commands per Bash call; see Traps.
- Widening what the guard denies. A command whose own TEXT spells an
  unbounded loop stays denied — that limit is pinned by a case and is the
  defensible side of the line.
- The consumer-side question of whether a session routes around the gate.
  Not measured, not this plan's.

## Acceptance

- Both Goal payloads DENIED. Feed each to the guard on stdin as the event
  delivers it, from a file rather than a heredoc — a Bash command whose own
  text spells an unbounded loop is denied by the guard itself, which is how
  the measurements above had to be taken:

  ```
  bash .agents/harness/pretool-bash-guard.sh <payload.json; echo $?    # 2
  ```

- Every case in the topic still holds. Counted on 2026-09-17, before any
  change: 13 `pbg_allowed` and 12 `pbg_denied`. Both totals may only grow.

  ```
  grep -c 'pbg_allowed "' .agents/harness/selftest/pretool-bash-guard.sh
  grep -c 'pbg_denied "'  .agents/harness/selftest/pretool-bash-guard.sh
  ```

- `./joharness.sh ci` — `ci: pass`. This is the SHIPS check: the layer syncs
  to every consumer, `cmd_ci` runs `.agents/harness/selftest.sh`, and that
  runs this topic — so the bar is met by the command a consumer runs, not
  only by one spelled here.
- Each new or changed line in the walk pinned. `./joharness.sh mutate
  .agents/harness/pretool-bash-guard.sh <line> <replacement>` names which
  cases red; a line no case reds is a line nothing tests. Every new line,
  not the ones that come to mind: the reverted attempt had three unpinned
  clauses, two of them found after its author had run this twice and thought
  it was done.
- The new cases fail without the fix. Revert the walk change, run the topic,
  and the two Goal payloads read exit 0 again. Green both ways pins nothing.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:end_re` — the end-finding regex and
  the `body` extraction below it. The two lines the rewrite replaces.
- `.agents/harness/pretool-bash-guard.sh:start_re` — `for` deliberately
  absent, which is right, and is why its `done` is available to be
  miscounted.
- `.agents/harness/pretool-bash-guard.sh:sleep_re` — what is tested against
  `body`, beside `count_re` and `arith_re`.
- `.agents/harness/selftest/pretool-bash-guard.sh:pbg_denied` — the
  assertion helpers, and the comment above the two-loops case explaining why
  one regex match cannot judge them.
- `docs/research/bash-guard-reads-prose-as-a-loop.md` — the answer, the
  reverted attempt, and what a rewrite owes.
- `joharness.sh:cmd_mutate` — usage, and what it does with a mutation that
  changes nothing.
- `joharness.sh:cmd_ci` — where the selftest runs, for the SHIPS claim.

## Traps

- NO FORKS in this hook. It runs in front of every Bash call in every
  consumer, and the perf row is budgeted at 0 external commands; reaching
  for `grep` here is meant to turn it red.
- FAILS OPEN, always. A shape it cannot read exits 0 and says nothing. A
  guard that denies when confused is worse than no guard.
- NEVER skip, disable or quarantine a case to get green.
- Never kick CI: no empty commit, no close-reopen.
- A test written for the fix must FAIL without it — revert, run, restore.
- The pull request's last commit before it opens deletes this plan file, the
  workstream file, and the research node above. Deferred, they land on
  `main` and the next session reads finished work as current.

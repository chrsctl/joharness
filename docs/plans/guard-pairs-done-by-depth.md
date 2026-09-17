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

Issue #271, and the open question it is the other end of. The guard walks a
command one loop at a time and takes the FIRST `done` as the end of the loop
it just found. That single choice has four consequences, and they point in
both directions — commands with no unbounded wait are refused, and commands
that hold one are allowed. Measured in this checkout, 2026-09-17, payloads
fed on stdin as the event delivers them (runner in Acceptance):

```
exit=0  until grep -q x /tmp/f; do for y in 1 2; do : ; done; sleep 20; done
exit=0  i=0; while [ $i -lt 3 ]; do until grep -q x /tmp/f; do sleep 20; done; i=$((i+1)); done
exit=2  echo "wait while the suite finishes"; timeout 900 bash -c 'until grep -q PASS /tmp/out; do sleep 15; done'; cat /tmp/out
exit=2  echo "the UI floor moved while they were written" && for d in 2 4; do true && break || sleep $d; done
```

The first two are waits with no bound, allowed. The last two hold no
unbounded loop at all and are refused; swap the prose `while` for `when` and
both read exit 0, so the prose keyword is the whole cause.

Each is the same pairing read from a different end — which `done` closes
this keyword, and which keyword owns this `done`. The research node settled
that they are ONE defect: a narrowing at either end was built, measured and
reverted there, and it opened a wider hole than it closed. So this plan
closes both ends or neither.

**What the history says, because it answers a design question.** The guard
has had exactly two states in all of this repository's history:

```
git log --oneline --all -- .agents/harness/pretool-bash-guard.sh
be726cb  harness: fix the guard's decision, and the registration that voided it
f9ea7d6  harness: refuse an unbounded wait before it runs
```

`f9ea7d6` matched once, greedily, over the whole command. Fed the four
payloads above it reads `2, 0, 0, —`: it got payload 1 right and both prose
shapes right, and it got the two-loops case wrong, which is why `be726cb`
replaced it with the per-loop walk on 2026-09-05. So payload 1 and both
false positives are REGRESSIONS from that walk; only payload 2 predates it.
The whole-command reader had the ends this plan is fixing already right, and
lost the middle. Whatever replaces the walk has to hold all three at once.

## Scope

- `.agents/harness/pretool-bash-guard.sh` — replace how the walk decides
  which `done` closes a keyword. Walk forward counting `do` up and `done`
  down; the `done` that returns the count to zero is this loop's own. The
  walk already does prefix arithmetic with `${rest%%"$kw"*}` and
  `${rest%%"$end"*}`, so this is the same style.

  Four lines, not two. The end-finder is `[[ $rest =~ $end_re ]] || break`,
  `end="${BASH_REMATCH[0]}"` and `body="${rest%%"$end"*}"`; the advance
  `rest="${rest#*"$end"}"` two lines below is part of the same decision, and
  `end_re` goes dead or changes meaning with them.

  **A nested loop must still be judged.** This is payload 2 and it is the
  trap a depth counter walks straight into: with the wider span the outer
  loop's own counter bounds it correctly, the walk `continue`s, and the
  advance past the outer `done` swallows the inner `until` whole — allowed,
  never judged, and no keyword left for the next pass to find. A rewrite
  that fixes the end-finder and leaves that advance alone leaves payload 2
  exit 0. Verified against a prototype of exactly that change, 2026-09-17.

  **A counter bounds only the loop it belongs to.** Same reason, other
  direction: the span now contains other loops' text, and `count_re` or
  `arith_re` read over it lets a harmless inner counter bound a dangerous
  outer loop. That is the defect `be726cb` was written to prevent.

  Decide, and record in the file's own comment, whether `sleep` is looked
  for over the whole span or only in text belonging to this loop. The answer
  does not carry from the counters: a `sleep` inside a nested `for` IS a
  sleep the outer loop performs every iteration, while a counter inside it
  bounds nothing outside it.

- `.agents/harness/pretool-bash-guard.sh`, the deny message — the node
  records it as owed beside the rule, not instead of it. It prints `no
  timeout, no iteration counter` at a command carrying `timeout 900`, two
  lines above prescribing that same spelling. Whatever the rewrite decides,
  the message may not name a bound the command it is refusing already has.

- `.agents/harness/selftest/pretool-bash-guard.sh` — a case for each of the
  four payloads in Goal, plus the two shapes the reverted narrowing broke,
  which no case covered and which a green suite said nothing about:

  ```
  until docker compose logs db 2>&1 | grep -q "ready for connections"; do sleep 5; done
  until grep -q "ready for merge" /tmp/out; do sleep 20; done
  ```

  Both are denied today and must stay denied. They are cases because the
  last change here made them pass and nothing noticed.

- `docs/research/bash-guard-reads-prose-as-a-loop.md` — deleted by this
  plan's pull request, and only once the two prose shapes in Goal read exit
  0. That node's question is the false-positive end; deleting it while its
  own reproducers still fire is the "the question comes back" failure the
  research protocol exists to prevent. Its reasoning goes into the guard's
  header comment, which is what its `graduates:` names — not a rule line:
  what has to survive is that the two ends are one defect, that a clause at
  either end pays at the other, and the reverted attempt's measurements.

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
  defensible side of the line. The prose shapes in Goal are the other side:
  a keyword in a sentence, with the only real loop bounded.
- Restoring `f9ea7d6`'s single greedy match. It is quoted because it answers
  what a correct reader must hold at once, not as a destination: it allowed
  a counter in a harmless first loop to bound a dangerous second one, which
  is incident command two.

## Acceptance

All four Goal payloads read the right code. Feed each to the guard on stdin
as the event delivers it, from a FILE — a Bash command whose own text spells
an unbounded loop is denied by the guard itself, which is how every reading
in this plan had to be taken:

```
bash .agents/harness/pretool-bash-guard.sh <payload.json; echo $?
```

- the two waits with no bound → `2`
- the two prose shapes → `0`, and the `when` control still `0`
- both readiness shapes above → `2`

- Every case in the topic still holds. Counted 2026-09-17, before any
  change: 13 `pbg_allowed` and 12 `pbg_denied`. Both totals may only grow.

  ```
  grep -c 'pbg_allowed "' .agents/harness/selftest/pretool-bash-guard.sh
  grep -c 'pbg_denied "'  .agents/harness/selftest/pretool-bash-guard.sh
  ```

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed. The diff touches non-`*.md` files
  under `.agents/harness/`, which is step 7's condition for it, and the
  reverted attempt's two broken shapes were invisible to a green `ci` AND a
  green `verify`.
- Each new or changed line in the walk pinned. `./joharness.sh mutate
  .agents/harness/pretool-bash-guard.sh <line> <replacement>` names which
  cases red; a line no case reds is a line nothing tests. Every new line,
  not the ones that come to mind: the reverted attempt had three unpinned
  clauses, two of them found after its author had run this twice and thought
  it was done.
- The new cases fail without the fix. Restore the walk, run the topic, and
  each new case reds. Green both ways pins nothing.
- **SHIPS, and what that does NOT cover here.** `ci`'s ship-scope reads this
  plan's `scope:` and says the guard reaches every consumer at its next
  sync. Its suite does not:
  `.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY` exempts
  `.agents/harness/selftest.sh` and `CANONICAL_ONLY_DIRS` exempts
  `.agents/harness/selftest`, so a consumer's `./joharness.sh ci` prints
  `not here (canonical-only...)` and runs ZERO of the cases above. The check
  a consumer can run is the payload feed itself, against its own synced
  copy — the same four readings, same command, in a consumer checkout. Name
  that in the pull request, because the regression suite stays here while
  the thing it guards ships everywhere.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:end_re` — the end-finding regex,
  the `body` extraction and the `rest` advance below it. The decision this
  plan replaces.
- `.agents/harness/pretool-bash-guard.sh:start_re` — `for` deliberately
  absent, which is right, and is why its `done` is available to be
  miscounted.
- `.agents/harness/pretool-bash-guard.sh:sleep_re` — what is tested against
  `body`, beside `count_re` and `arith_re`.
- `.agents/harness/pretool-bash-guard.sh:deny` — the message that names a
  bound the refused command may already carry.
- `.agents/harness/selftest/pretool-bash-guard.sh:pbg_denied` — the
  assertion helpers, and the comment above the two-loops case explaining why
  one regex match cannot judge them.
- `docs/research/bash-guard-reads-prose-as-a-loop.md` — the answer, the
  reverted attempt, the five instances, and what a rewrite owes.
- `.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS` — why the suite
  does not ship with the guard.
- `joharness.sh:cmd_mutate` — usage, and what it does with a mutation that
  changes nothing.
- `joharness.sh:cmd_ci` — where the selftest runs here, and the branch that
  prints `not here` in a consumer.

## Traps

- NO FORKS in this hook. It runs in front of every Bash call in every
  consumer, and the perf row is budgeted at 0 external commands; reaching
  for `grep` here is meant to turn it red.
- FAILS OPEN, always. A shape it cannot read exits 0 and says nothing — a
  depth count that never returns to zero is such a shape. A guard that
  denies when confused is worse than no guard.
- The guard refuses the commands that test it. Its own incident payloads,
  a heredoc carrying them, and a commit message quoting them have all been
  denied. Write payloads and commit messages to disk with a non-shell tool
  and use `git commit -F`; do not work around the gate any other way.
- NEVER skip, disable or quarantine a case to get green.
- Never kick CI: no empty commit, no close-reopen.
- The pull request's last commit before it opens deletes this plan file, the
  workstream file, and the research node above. Deferred, they land on
  `main` and the next session reads finished work as current.

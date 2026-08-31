---
plan: drain-misses-requirements
urgency: urgent
agent: sonnet
effort: low
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest
---

## Goal

`drain` reports **DRAINED** while the highest-ranked entry point in the
queue is non-empty, which is the one thing it was built not to do.

Measured on `main` at `4bb6949`, 2026-08-31:

```
$ ./joharness.sh drain
DRAINED — no free plan, no open question.
  Supervised stops here and asks (step 2). It does NOT invent work

$ bash .agents/harness/queue-context.sh
Requirements without plans — planning outranks the plan queue:
  docs/product/unsupervised-mode.md  [normal, UNPLANNED — decompose into plans]
No plans on origin/main. Entrypoint: plan the requirements above
```

`drain_next` reads the queue hook's output with

```
sed -n 's#^  \(docs/\(plans\|research\)/[^ ]*\.md\)  \(.*\)$#\1 \3#p'
```

`docs/product/` is not in that alternation, so a requirement waiting to be
decomposed is invisible to it. Step 2 ranks requirements ABOVE plans —
"planning outranks the plan queue", the hook's own words — so this is not a
missing extra, it is the top of the queue.

Cost: a session running `/drain` stops with the queue's first item
outstanding, and in supervised mode it stops and tells the human there is
nothing to do. That is the idle-with-a-full-queue state `/drain` was measured
into existence to prevent.

## Scope

- `drain_next`: read requirement lines too, and rank them first.
- The `NOT DRAINED` summary line: its count comes from `N free plans`, which
  a requirement does not have. Say what is actually next rather than printing
  a plan count beside a requirement.
- `DRAINED`'s wording: it currently claims "no free plan, no open question",
  which was true and insufficient. It must be a statement about every
  entrypoint it checked.
- Cases in `.agents/harness/selftest/drain.sh` for: a repo with only an
  unplanned requirement, and one with both a requirement and a free plan
  (the requirement wins).

## Out of scope

- Changing what `queue-context.sh` prints. It is right; `drain` was reading
  it partially.
- Issues. They outrank requirements, and `drain` does not read GitHub — the
  hook says so itself and that is a separate question from this one.
- Deciding whether the requirement on `main` should be decomposed now. That
  is blocked on a human read of `origin/claude/unsupervised-goal`
  (PR 152), and is not this diff's business.

## Acceptance

```
./joharness.sh drain      # NOT DRAINED, next: docs/product/unsupervised-mode.md
bash .agents/harness/selftest.sh                 # 0 failed
./joharness.sh ci                                # ci: pass
```

And the load-bearing one, since this is a fix and Loop step 5 now has a
command for it:

```
./joharness.sh mutate joharness.sh <line of drain_next's sed> '<the old pattern>'
```

must red the new cases. Green both ways means they pin nothing.

## Where to look

- `joharness.sh:drain_next` — the sed alternation.
- `joharness.sh:cmd_drain` — the `NOT DRAINED` and `DRAINED` branches.
- `.agents/harness/queue-context.sh` — "Requirements without plans", printed
  before the plan list, which is why first-match ordering already favours it.

## Traps

- The delimiter is `#` and not `|`, because `|` is BRE's alternation: with
  `s|...|` the `\|` reads as an escaped delimiter and the expression silently
  matches nothing — reporting a full queue as drained. That is how this
  function was written the first time, and it is the same failure this plan
  is fixing by another route.
- A requirement that already HAS plans must not be offered. The hook only
  lists unplanned ones under that heading, so match the heading's section
  rather than any `docs/product/` path anywhere in the output.

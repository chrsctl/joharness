---
plan: dispatch-names-the-core-wait
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/harness/selftest/dispatch.sh, .claude/commands/orchestrate.md, .agents/docs/orchestrated.md
---

## Goal

`dispatch` prints `DRAINED — nothing free` when every unclaimed plan is
`CORE ONLY` and slots idle. The orchestrator opens no plan and pushes the
human only on `status: blocked`, so nothing a human reads names the wait;
in gx two slots idled while two plans waited two to three days, one of
them the only plan of a requirement, with one core path among fourteen. Why, and the decision to keep the
de-rank: `.agents/docs/orchestrated.md`, Bounds, "A `CORE ONLY` plan is a
wait on a human". This plan makes the wait visible: one line under the
verdict, one push to the human per run.

## Scope

- `joharness.sh` — `dispatch`: when `drain_core_only` returns anything AND
  the verdict is any `DRAINED` line, print one more line under the verdict,
  the shape of the `past the stall window` line:
  `            <n> plan(s) wait on a human core edit (oldest <d>d): <stem> <stem>...`
  `<n>` = lines `drain_core_only` returned; `<d>` = whole days since the
  oldest plan's add commit on the base branch (`git log --diff-filter=A
  --format=%ct <base> -- <path> | tail -1`; unreadable = `?`). Stems in the
  queue's order, every one, never cut. The verdict WORD is unchanged: a
  `DRAINED ... exit` still exits. Never on `NOT DRAINED`, `OVERLAP-BOUND`
  or `PAUSED`: slots are not idle for this reason there.
- `.agents/harness/selftest/dispatch.sh` — one case on the shared fixture,
  every precondition set in the case: a plan whose `scope:` holds one core
  path and two non-core paths, alone on the queue, nothing in flight.
  Expect the `NOT YOURS — CORE ONLY` block, the exit verdict unchanged, and
  the wait line with `1 plan(s)`, `(oldest 0d)` and the stem. A second
  read with a free plan beside it: refute the wait line. Drop the fixture
  plan after.
- `.claude/commands/orchestrate.md` — "Report, every pass": print the wait
  line verbatim after the verdict. Then, per stem on it: `PushNotification`
  once carrying the stem, the plan path and the text `waits on a human core
  edit` — the `status: blocked` row's shape. The record is a RUN-SCOPED
  ledger key, since the plan has no in-flight entry to hang `notified=`
  on: add `[corewait=<stem>[,<stem>]]` to the ledger line in "## 4." beside
  `rescoped=`; a stem not yet listed = send and append it, else report
  only; drop a stem when dispatch no longer lists it. A `DRAINED ... exit`
  pass arms nothing, so each heartbeat run starts empty and pushes again:
  say so in one line, as true of a block. No `PushNotification` = the
  report carries it, say so once (Tools table row). Never spawn on it,
  never read it as work; the lead drop on `CORE ONLY` stays.
- `.agents/docs/orchestrated.md` — "How the harness runs": a row for the
  wait line under the `dispatch` row. Bounds, "A `CORE ONLY` plan is a
  wait on a human": rewrite the sentence opening `Plan
  `dispatch-names-the-core-wait` makes` to present tense (`dispatch`
  prints ..., the orchestrator pushes ...) and delete its tail `until it
  merges the verdict line is the whole reading`.

## Out of scope

- A route that builds a partly-core plan (manager, surveyor split, patch
  for the human). Decided against in Bounds; re-open with a research file,
  not here.
- A new verdict word, a new ledger key, a change to `queue-context.sh`'s
  marking or to `.agents/docs/plans/README.md`. The marking is right; the
  silence after it is the defect.
- Naming the stranded requirement on the line. The human opens the plan.

## Acceptance

- `./joharness.sh verify` — `0 failed`, the new case counted in the
  dispatch topic.
- Mutation: with the new `printf` in `dispatch` deleted from a scratch
  copy, the new case reds; restored, green. Record both runs in the
  workstream file's `## Review`.
- Scratch queue (one requirement, one plan serving it, `scope:
  .github/workflows/ci.yml, platform/web/src, scripts`, nothing in
  flight, `JOHARNESS_CONF` with `JOHARNESS_ENV=none`, `DRAIN_FETCH=0
  DISPATCH_FETCH=0 ./joharness.sh dispatch`) prints, in this order:
  `  nothing free`, the `NOT YOURS — CORE ONLY` block naming the plan,
  `verdict   : DRAINED — nothing free, nothing in flight: exit, the heartbeat re-seeds`,
  `            1 plan(s) wait on a human core edit (oldest 0d): crm-write-document-prints-a-pdf`.
- `./joharness.sh ci` — `ci: pass`.
- SHIPS: a consumer's `./joharness.sh ci` runs the harness selftest, so
  the new dispatch case is the check every consumer runs after its next
  sync; a consumer whose queue holds a partly-core plan reads the wait
  line under its own `dispatch` verdict.

## Where to look

- `joharness.sh:drain_core_only` — the list the line counts.
- `joharness.sh:cmd_dispatch` — the `past the stall window` line after the
  verdict: the shape and the indent to copy.
- `.agents/harness/selftest/dispatch.sh:dspplan` — the fixture helper; the
  first DRAINED case shows the exit verdict's exact text.
- `.agents/harness/selftest/queue-context-core-only.sh` — the `mixed`
  case: a partly-core scope reads `scope includes a core path`.
- `.claude/commands/orchestrate.md` — the health row `status blocked, no
  INVALID BLOCK?`: the notify-once shape and the `notified=` key.
- `.agents/docs/orchestrated.md` — Bounds, the paragraph this plan serves.

## Traps

- Never commit under `./joharness.sh protocol-paths`. `.github/workflows/ci.yml`
  appears only as fixture DATA in a `scope:` string.
- Never change the verdict word or its line: the orchestrator branches on
  `DRAINED`, and the dispatch selftest matches the line whole.
- The test must FAIL without the fix: run the mutation, record it.
- Caveman style and the glossary: `ci` fails on a banned spelling.

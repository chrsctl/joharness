---
plan: heartbeat-is-a-precondition
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .claude/commands/orchestrate.md, .agents/docs/orchestrated.md
---

## Goal

Issue 285, "Shape of a fix", items 1 and 2, plus one hole found closing
`docs/research/scheduler-outside-the-fleet.md`. An orchestrated run's
continuity is a chain of self-armed one-shot wakes, and `orchestrate.md` § 4
reads as the continuity mechanism. It is the CADENCE mechanism. Durability
is the heartbeat Routine's job, and `orchestrated.md` says so 300 lines away
in a file the orchestrator is not told to read. Measured cost of the gap:
18 days and 2 hours idle with a full queue, three managers alive, work
finished and unmerged — the terminating link reading `SUCCEEDED` and
byte-identical to the nineteen healthy links before it. 285 calls item 1
"what would have surfaced this on 2026-09-17 rather than 18 days later".

Both files are protocol text, so the queue hook marks this `SUPERVISED ONLY`
from `scope:` and ranks it out of the free list
(`.agents/harness/queue-context.sh:519-521`). That is deliberate: this is a
human's change to make.

## Scope

- `.claude/commands/orchestrate.md` — three edits:
  - Step 0, a new precondition: read whether a live heartbeat Routine exists
    for this repo (a Routine with a `cron_expression`, `enabled`, firing a
    fresh session), and when there is none say so in the report, loudly and
    every pass: "no heartbeat: this fleet dies with this session." It does
    NOT create one — that is spend, and the human's
    (`.agents/harness/AGENTS.md`, Decide alone). One read; it converts a
    silent single point of failure into a visible one.
  - § 4: say what the `send_later` chain is not. It is the cadence, at
    `JOHARNESS_HEALTH_MINUTES` (default 10). It is not durability: a chain
    link that is delivered but never executed ends the fleet and records
    `SUCCEEDED`, so no later pass can tell. Point at the heartbeat for the
    durability half.
  - Step 0 precondition 2, the one-orchestrator check: give it the
    frozen-but-`RUNNING` branch it lacks. Today a session that finds another
    titled `orchestrator: <owner/repo>` with `session_status: RUNNING` exits
    before the health pass at `## 2`. An orchestrator frozen but still
    `RUNNING` therefore makes EVERY heartbeat firing exit, forever, while
    the Routine's own record stays healthy. Decide and write what a firing
    does there — the file's own `stalled` row already defines the state
    ("`RUNNING`, `status_detail` unchanged across two passes", measured
    byte-identical across 172.273s), and the same file forbids a one-signal
    verdict on a control-plane field, which this precondition currently is.
- `.agents/docs/orchestrated.md` — the why-explanation for all three, and
  extend the two cases it already names ("Firing over a live orchestrator is
  safe… Firing over a dead one is the point") to the third that is neither.

## Out of scope

- Creating, pricing or scheduling the Routine. Recurring spend, the
  human's; the mode may report its absence and must not fix it.
- The repo-quiet alert (a scheduled workflow opening an issue when `main`
  has merged nothing in N hours). A new always-on alerting mechanism is
  product direction. Named in PR for `scheduler-outside-the-fleet` and left
  for the human.
- Issue 249's duplicate-holder check (flag any branch named by more than one
  non-archived session). A health-table row, a different question.
- Any change to `send_later`'s cadence value or to the chain itself. 285 is
  explicit that the chain is not wrong as a cadence: 19 consecutive passes,
  median gap under 12 minutes.

## Acceptance

- `grep -n -i heartbeat .claude/commands/orchestrate.md` — more than today's
  single unrelated hit at `:639`; at least the step-0 precondition and the
  § 4 pointer.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh context` — the instruction chain did not grow: step 0 is a
  read and a report line, not a new procedure.
- A session reading only `orchestrate.md` can answer, without opening
  `orchestrated.md`: does this fleet survive my container stopping? Today it
  cannot.
- Plan `ci` calls SHIPS: `orchestrate.md` is synced to every consumer, so a
  consumer's orchestrator gets the same report line.

## Where to look

- `.claude/commands/orchestrate.md:step 0` — preconditions; precondition 2
  is the one-orchestrator check that needs the third branch.
- `.claude/commands/orchestrate.md:§ 4` — `send_later`, armed at
  `JOHARNESS_HEALTH_MINUTES`.
- `.agents/docs/orchestrated.md:Heartbeat` — the live/dead cases to extend.
- `.agents/docs/unsupervised.md:Heartbeat` — the two chain-ending shapes,
  the durability-not-cadence rule, and why `last_run` is never the check.
  Note: `docs/plans/drop-unsupervised-docs.md` moves this section into
  `orchestrated.md`; read whichever file holds it when this plan runs.

## Traps

- Protocol text. A session under `orchestrated` or `unsupervised` must
  never commit here (`./joharness.sh protocol-paths`,
  `.agents/docs/unsupervised.md` Bounds). The `SUPERVISED ONLY` marking is
  derived from `scope:` — do not hand-write a marker.
- Never let style eat a fact (`.agents/docs/caveman.md`); net instruction
  size must not grow for a report line.
- A broken link is red in `ci`'s anchor lint.
- Trust counted numbers, never written numbers — including the ones in this
  plan. Re-derive `JOHARNESS_HEALTH_MINUTES` and the `:639` hit before
  relying on either.

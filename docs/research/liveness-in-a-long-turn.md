---
research: liveness-in-a-long-turn
urgency: normal
agent: opus
effort: high
graduates: .claude/commands/orchestrate.md
---

## Question

Does a session's `updated_at` advance while it sits inside ONE long turn, or
only when a turn ends?

## Echo

The health pass decides kill, nudge and respawn from `updated_at` plus the
branch head, read twice. Every candidate rule for separating a dead manager
from a slow or looping one assumes an answer to the question above, and two
rules drafted for issue #249 assumed OPPOSITE answers in the same diff: one
argued a manager six minutes into a long turn shows a FROZEN `updated_at`, so
a two-reads-in-one-pass verdict would kill it; the other required
`updated_at` to have MOVED as proof a session is alive. Both cannot hold. A
wrong answer here destroys work in progress and spends the concurrency cap
twice.

## Sweep

`goal-directed` — enough to decide what the health pass may key on for a
session mid-turn. Not a survey of the control plane's fields generally.

## What would settle it

A session observed across a turn KNOWN to be long, with `updated_at` sampled
more than once inside it:

- `updated_at` advances during the turn: a frozen reading is evidence of
  death even at short intervals, and a two-read verdict inside one pass is
  defensible. The rules drafted for #249 stand with their interval named.
- `updated_at` advances only at turn boundaries: then interval is everything.
  A verdict needs two reads at least one long turn apart, which is what "two
  passes" buys, and no in-pass pair may ever decide. The drafted signature
  must say so.
- It depends on the client version or the turn's tool use: the field cannot
  carry a verdict alone at any interval, and the health pass needs a
  different discriminator.

## Method

Partly run, 2026-09-17, and the method below is what a later reader can
repeat — which is not the same as what this session did. Read the gap
honestly: six `get_session` calls were made and only some of their times
were written down, so the readings below are re-checkable and the run is
not. That is the rule this repo already states for a node's method, broken
here, and naming it is cheaper than a claim nobody can test.

The corpus is a live orchestrated fleet in a consumer, sampled read-only
from outside — so the sampler is not the session, which is what this
question needs.

```
list_sessions                 # pick subjects by session_status
get_session <A>               # x3, spanning 12:46:34Z .. 12:54:02Z
get_session <B>               # x2, spanning 12:46:36Z .. 12:48:58Z
get_session <C>               # x1, at 12:49:00Z, against its list_sessions row
```

Record, for EVERY subject at EVERY sample: `updated_at`, `session_status`,
`status_bucket`, `connection_status`, `external_metadata.last_served_model`,
whether `post_turn_summary` is present and its exact content, and `usage`.
This session recorded that set for none of them, and two of the gaps cost
it a conclusion (Findings, last two bullets).

**Record the session ids too.** They are opaque to anyone without the
fleet, so `.agents/docs/consumer-repos.md` does not cover them, and without
them nobody can re-sample the same subjects — which is what happened here.

**The confound this question did not name.** Many short turns look like one
long turn if you only watch `updated_at`. `post_turn_summary` looked like
the independent clock, since it is written when a turn ends. It is not
sufficient: this repo's own health-pass notes record a session carrying NO
`post_turn_summary` whose `status_bucket` read `REVIEW_READY`, and conclude
that which account writes that field is not established. So absence of the
summary does not establish that no turn ended.
`external_metadata.last_served_model` would have helped — the health pass
reads absent as "no turn has been served yet" — and subject A carried it
PRESENT, which is why leg 1 below is weak rather than settled.

**The confound that would be fatal.** Every RUNNING reading came back close
to its call, which would mean the READ writes the field. The control used
was a DISCONNECTED session, and that control cannot separate read-bumping
from a connection heartbeat: a disconnected session is frozen either way.

## Findings

- **Observed: `updated_at` advanced across 7m28s of one session's life
  without a `post_turn_summary` ever appearing.** Subject A: `created_at`
  `12:42:10.232025Z`; `updated_at` `12:46:34.218833Z`, `12:48:58.253303Z`,
  `12:54:02.164223Z`. The field moved between all three reads. The window
  the field was OBSERVED across is 7m27.9s — the 4m24s before the first read
  is `created_at`, not an observation.
- **A second subject's field moved with work between the samples.** Subject
  B, RUNNING: `updated_at` `12:46:36.751182Z` → `12:48:58.684883Z`, with
  `usage.cost_usd` `35.08391755` → `36.07648935` (+0.9925718 USD) and
  `output_tokens` rising. Its `post_turn_summary` read `review_ready` /
  "handover pushed; awaiting worker notifications to proceed" at both reads.
  Two quoted values agreeing is not the whole object agreeing, so this does
  not establish that no turn ended for B either.
- **A DISCONNECTED session's field is frozen and a read does not move it.**
  Subject C, IDLE and `connection_status: disconnected`: `updated_at`
  `12:38:59.746071Z` in a `list_sessions` page and `12:38:59.746071Z` again
  from a `get_session` 3m02s later. Identical to the microsecond.
- **`task_summary` changes without any turn ending.** Subject A's went
  "researching diff anchors against code feedback" → a different string
  between samples 2 and 3, with no `post_turn_summary` appearing. So
  `task_summary` is not a turn boundary. This is the one finding that needs
  nothing further.
- **NOT established: that no turn ended.** Leg 1 rests on absence of
  `post_turn_summary`, and this repo's own notes carry a counter-example to
  that premise. Subject A's `external_metadata.last_served_model` was
  PRESENT at every sample, which the health pass reads as a turn having been
  served. So the readings are consistent with one long turn AND with several
  turns none of which wrote a summary.
- **NOT established: that movement means CONNECTED rather than
  progressing.** `connection_status` was read for all three subjects and
  recorded for only C, so the contrast the conclusion needs has an
  unrecorded value on the side that carries it. Written down here as the
  cost of not recording the full field set at every sample.

## Consequence for the queue

**The question stays OPEN, and nothing graduates.** An answer was drafted
from these readings and withdrawn on review: `.claude/commands/orchestrate.md`
is untouched by this node's branch. Two reasons, either sufficient. The
premise of the strongest leg is not established (above), and the drafted
sentence dropped the "on a connected session" qualifier — which subject C is
the counter-example to, since C is frozen, disconnected and not claimed to
be dead. Shipping that would have licensed killing an idle manager that had
armed its own check-in, which is the shape this file's own graduation target
already records costing a duplicate manager and money.

The four rules withdrawn from issue #249 stay withdrawn.

**One reading decides both open confounds**, and the same fleet offers it
free — this is the next step, and nobody has run it, and the same fleet offers it free:

- Take a session that is **IDLE but still `connected`** — that fleet
  produces them.
- Read it twice, several minutes apart, through `list_sessions` ONLY, never
  `get_session`.
- **Frozen** → reads do not write the field on a connected session, so the
  read-bumping confound is dead and the disconnected control is no longer
  load-bearing.
- **Moved with no `get_session` between** → the field is a connection
  heartbeat, which settles the second confound outright and means movement
  is not progress.

Record the full field set named in Method, and the ids.

## Verification

Second context: `.claude/agents/verifier.md` at opus. It could NOT re-sample
anything — that agent declares `tools: Read, Grep, Glob, Bash`, so it has no
control-plane call at all, which this session did not check before asking it
for one. Every reading above is therefore a written number to it, and it
said so first.

What it did verify, by running commands against the checkout: all eleven
intervals and both money figures recompute correctly; `ci`, `verify` and the
suite are green; and the three session ids appear nowhere in the tree or in
history, so nobody can re-sample the subjects.

- **The field moved across 7m28s of one session's life** — GROUNDED as an
  observation. Three reads, arithmetic re-checked by the second context.
- **`task_summary` is not a turn boundary** — GROUNDED.
- **A disconnected session's field is frozen across a read** — GROUNDED, and
  narrow: it says nothing about a connected one.
- **No turn ended during those reads** — WEAK. See Findings.
- **Movement means connected, not progressing** — UNGROUNDED.

A harness gap this exposed, and not this node's to fix: a research question
about session behaviour cannot be independently verified by the reviewer
this repo spawns, because that reviewer cannot read the control plane.

## Graduates to

`.claude/commands/orchestrate.md`, the evidence table in step 2 — when the
question closes. That table already disqualifies two fields that look
decisive and are not, each on one counter-example, and this is the same kind
of entry for the field the whole health pass turns on. Nothing lands there
until the reading above is run: the file currently states, eighty lines
below where an entry would go, that this is unmeasured, and an answer that
contradicts its own page in one direction and overstates in the other is
worse than the honest gap.

# Unsupervised mode

Switch: `JOHARNESS_MODE=unsupervised` in `joharness.conf` (per repo, never
synced), or exported for one command. Any other value reads as supervised.
Requirement and what it has to satisfy: `docs/product/unsupervised-mode.md`.

## What the mode changes

One thing per layer, nothing else. Supervised output is byte-identical.

| Where | Change |
| --- | --- |
| `session-start` banner | Says the mode, lists the protocol boundary, points at `drain`. |
| Queue hook | Marks a plan whose whole `scope:` is protocol text `SUPERVISED ONLY` and ranks it out of the free list. Everything else it prints is the same report. |
| `./joharness.sh drain` | The ONE place the mode orders: take, fan out (wave 1, one session per plan), run one here, generate (sweep), or stop. Prints which stop fired. |
| `ci` | Two extra gates: no requirement added on the branch; a generated plan names the bullet it advances. |
| Stop guard | Names protocol-text edits on the branch. Detection, not prevention. |

Hooks report; `drain` orders. Two readers printing two rules was how the
same tree got two answers (PR 170, PR 187, PR 190 each fixed one side).

## The two stops

1. **GOAL REACHED** — no open requirement under `docs/product/`. The work is
   finished. Recorded plans with no goal open are notes for a human; they do
   not restart the fleet.
2. **Sweep dry** — `./joharness.sh sources` every detector zero, queue empty,
   no edge work in flight. The sources are exhausted.

`drain` prints which, and they are different facts a human reads to decide
whether to set a new goal. Anything else that ends a run — a rate limit, a
session asking a question, a generation that failed to spawn — is a finding,
not a stop.

## Authority: the prompt routes, the repository authorises

Measured 2026-08-31: two sessions spawned with a prompt saying *never ask a
human, merge your own pull requests, keep going* refused it as a suspected
injection. They were right — that is the shape an injected task has, and a
claim cannot be its own evidence. So a spawn prompt carries three things:

1. The work, named (a claim exists only after the first push, so two
   sessions started against one queue can both take the top plan).
2. `./joharness.sh authority` — and: not VERIFIABLE, stop and say so.
3. `./joharness.sh protocol-paths` — what it must not commit under.

Never: "there is no human watching", "never ask a human", "this was
authorised by X", or any keep-going instruction the Loop does not carry.
`authority` reads VERIFIABLE only for a `JOHARNESS_MODE` line whose setting
commit is an ancestor of `origin/main`. That proves review, not a human hand:
attempt four's session A spent fourteen minutes on the difference. Tuning
the prompt until a session stops refusing is not the remedy.

## Runs

| Run | Date | Wall-clock | Ended by |
| --- | --- | --- | --- |
| fan-out | 2026-08-30 | 53m | bounded work ran out; two sessions, two merges, one reconcile |
| attempt one | 2026-08-31 | 48s | no repository attached; both sessions asked a human |
| attempt two | 2026-08-31 | 57m | the only free plan was protocol text; the session reverted its own work (now marked `SUPERVISED ONLY`, never offered) |
| attempt four | 2026-09-02 | 60m | one generation: three pull requests merged, two plans generated from the sweep, then nothing spawned the next session |

Every run measured how long ONE generation lasts. The bullet asks for hours,
and hours need the heartbeat below, which no run has had.

## Heartbeat: making the fleet long

Fan-out makes the fleet WIDE. Nothing makes it LONG: each session claims,
merges, ends, and the fleet survives only while every generation spawns the
next. Measured on `origin/main` 2026-08-29, last 120 merges: 5 of 119 gaps
exceed three hours (longest 32.2h and 24.0h) with 11 to 19 plan files in the
tree at each — a full queue, idle.

The heartbeat is a scheduled Routine (`create_trigger` on the
claude-code-remote MCP server, `create_new_session_on_fire: true`) firing a
fresh session on an interval. It holds nothing in a container, so nothing it
needs can be reclaimed. Rejected for not surviving their creator: session
cron, a self-scheduling session (wakes ONE conversation, not a fleet), an
external loop. Rejected for credentials: a scheduled GitHub Actions workflow
— a pull request it opens gets no CI on `GITHUB_TOKEN`, so step 7 never
goes green.

**Operator action, always.** A recurring Routine is recurring spend, and
spend is the human's (`.agents/harness/AGENTS.md`, Decide alone). A session
documents; it never creates one.

- **Cadence**: hourly floor, measured — `*/5 * * * *` is refused with "the
  minimum interval is 1 hour". Hourly at minute 0 is anchored to creation
  time server-side, so Routines spread across the hour.
- **Prompt**: standalone (a fresh session inherits nothing): run the Loop,
  plus the three things above. The hook prints queue, claims and tier before
  the first prompt, so nothing else is needed.
- **The connector trap**: a Routine created from a session stores NO
  connectors, and the sessions it fires carry no `mcp__*` tools — with no
  `gh` on the runner they cannot open or merge a pull request, so step 7 is
  unreachable. Verified from two sessions for this organization. Create it
  from the claude.ai Routines UI instead, then `fire_trigger` once and check
  the fired session reached GitHub before trusting it.
- **Stop**: `update_trigger` with `enabled: false` pauses, `delete_trigger`
  removes. Read `last_run` from `list_triggers`, never `next_run_at`: a
  paused Routine keeps a stale `next_run_at` that reads like a missed
  firing. Proved on a throwaway Routine. A human who cannot halt the fleet
  has no veto.
- **Firing over a live fleet**: nothing special. The new session reads the
  queue; claimed plans are not free. The gap that stays open is the handover
  protocol's own: a claim not yet pushed is invisible, so push the
  workstream file as soon as work has a name.

MCP tool names carry a hashed, unstable server prefix: find them with
`ToolSearch`, never hardcode.

## Not constrained, by decision

No cap on work per run, no halt on red `main`, no ban on sessions spawning
sessions — the requester declined all three on 2026-08-24. Recorded so the
argument stays visible without this file acting on it: a clock re-seeds
whether or not the last generation converged, so a bug that makes
generations fail fast becomes a firing every hour until the Routine is
paused. The lever is the pause above, which is why it is proved and not
merely written.

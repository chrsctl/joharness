# Unsupervised mode

Switch: `JOHARNESS_MODE=unsupervised` in `joharness.conf` (per repo, never
synced), or exported for one command. Any other value reads as supervised.
Bounds, design, mechanism and the runs so far are all below. The
requirement that specified this mode retired once the harness had
delivered everything it could; what it asked for that no code can deliver
— a fleet that runs for hours — needs the heartbeat, and lives in issue 165
of the canonical repo (`chrsctl/joharness`), not of whatever repo is
reading this.

The mode is thin on purpose and earns its switch on ONE distinction: is a
human present. Every piece of it is something a heartbeat-fired session
needs and an attended one must not have: the table below is the list, and
a row that does not turn on that question belongs somewhere else.

A third value, `orchestrated` (beta), answers the same question the same
way and adds one more: who dispatches. Every bound below binds it too,
through one predicate (`joharness.sh:unattended`); what it adds is in
[`orchestrated.md`](orchestrated.md). "Unattended" in this file means
either value.

## What the mode changes

One row per layer, and the rows are the whole difference. Supervised sees
none of them: no branch on the mode changes what an attended session gets
out of the same tree. That is a claim about one tree — removing the mode's
machinery changes supervised output like any other edit.

Every row below describes UNSUPERVISED. Orchestrated shares the boundary,
the merge gate, the requirement ban and the no-inventing edge — the Bounds
below, which is what "unattended" means here — and differs in every row of
this table; `orchestrated.md` has its own.

| Where | Change |
| --- | --- |
| `session-start` banner | Says the mode, lists the protocol boundary, and says the queue is the whole of the work: `drain` names the item, take it, merge your own pull request, at DRAINED exit. |
| Queue hook | Marks a plan with ANY protocol path in `scope:` `SUPERVISED ONLY` — the label says whether that is the whole scope or part of it — and ranks it out of the free list. Everything else it prints is the same report. |
| `./joharness.sh drain` | The same verdict as supervised, with the mode's lines around it: under `next:`, the edge-first line when edge work is in flight, then a spawn line naming every other free plan with its tier (claim by push, detect at merge — a collision is the reconcile step 7 already requires); before DRAINED, the NOT YOURS block naming the marked plans; under DRAINED, exit — the heartbeat re-seeds, nothing is invented. |
| `ci` | One extra gate: no requirement added on the branch. |
| Stop guard | Names protocol-text edits on the branch. Detection, not prevention. |

Hooks report; `drain` orders. Two readers printing two rules was how the
same tree got two answers (PR 170, PR 187, PR 190 each fixed one side).

## The one stop

DRAINED, at the queue edge, supervised and unsupervised alike. A session
takes one item, runs the Loop on it, exits; the heartbeat fires the next.
(Orchestrated splits this: a manager's stop is its own merge, and the
orchestrator stops at DRAINED only with nothing in flight.) Nothing is invented at
the edge: work enters the queue as an issue, a requirement, or a plan through
a pull request, and only there. Anything else that ends a run — a rate
limit, a session asking a question, a generation that failed to spawn — is
a finding, not a stop.

## Bounds

Three rules the mode does not relax. They outlive any spec that asked for
the mode, which is why they are here rather than in a requirement that
retires.

- **Protocol text is off limits to a session running unattended**, wherever
  it lives. The rule is the role; `joharness.sh:protocol_paths` is its
  mechanical expression, read by the banner, the Stop guard and the queue
  hook. The consequence — a plan with any protocol path in `scope:` is
  marked and de-ranked — is the queue-hook row in the table above; the
  reason it marks on ANY is here: the guard counts any such path in the
  diff and acceptance is all-or-nothing, so a partly-protocol plan cannot
  be finished either. Measured in this repo: attempt two spent 55 minutes
  on the all-protocol shape, and the partly-protocol one was found on
  2026-09-02 (canonical `main` f9fb932) with `drain` answering `next:` on a
  plan whose own Traps said supervised session only. Sandbox configuration
  (`.agents/env/`) is not
  protocol. The list covers its own machinery: `joharness.sh` and
  `.claude/settings.json` — and, since orchestrated mode, `joharness.conf`,
  which holds the mode line `authority` verifies and the orchestrator's
  cap (`orchestrated.md`, Bounds).
- **Merging uses the step 7 conditions unchanged.** The mode removes the
  human, never the gate.
- **No unsupervised session writes a requirement**, and `ci` reds the
  branch that does (`joharness.sh:lint_requirement_writes`). The queue is
  the human's to fill, and a fleet that writes its own work has no edge to
  stop at. Editing one is fine — annotating it with a measured result is
  the mode reporting its own results; ADDING one is the circularity.

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
| attempt four | 2026-09-02 | 60m | one generation: three pull requests merged, two plans generated from the sweep, then each session declared itself done and nothing spawned the next. Both generated plans were `SUPERVISED ONLY` and both sessions claimed and edited them anyway — the marking was printed, never read at claim time; one crossing reached `origin` before its revert (PR 195) |

Every run measured how long ONE generation lasts. The bullet asks for hours,
and hours need the heartbeat below, which no run has had.

## Getting it into a child

`bootstrap-consumer.sh` asks, once, at first contact, and writes the answer
into the child's own `joharness.conf`. That file is consumer-own and the
steady-state sync never touches it, so nothing re-asks and no later sync
overwrites what the child answered. It is one of five questions the bootstrap
puts — the others pick the environment layer and how the repo verifies itself
(`.agents/docs/consumer-repos.md`). `--mode <supervised|unsupervised>` answers
it for a run with nobody at a terminal (`orchestrated` is accepted there
too, never offered by the interview); a run with neither flag nor terminal
takes supervised and says why it did not ask.

One default, two bootstrap shapes, and they treat what the child inherits
oppositely on purpose:

| Bootstrap shape | The mode line |
| --- | --- |
| fresh, empty target | seeded with the answer |
| fresh, target brought its own conf | that conf keeps everything else; its mode line is SET |
| whole clone | inherited line OVERWRITTEN with the answer |

The whole clone is the reason this is forced rather than optional. It carries
canonical's own conf; canonical is flipped for the attempts in the table
above and reverted when each ends; so a clone taken mid-attempt would come up
unattended because of WHEN it was copied. `--env` is deliberately the other
way — an inherited environment layer selection is a choice somebody made for
that repo, so it stands unless somebody is asked. Every other question in the
interview offers the value already in force as its default; this one always
offers `supervised`. Autonomy is not the kind of thing a repo should acquire
by being copied.

Saying yes configures; it starts nothing. The child still needs the heartbeat
below, and the bootstrap says so both at the prompt and after the answer.

## Heartbeat: making the fleet long

Fan-out makes the fleet WIDE: one session per free plan as `drain` lists
them, every wave, and a collision between two is the reconcile step 7
already requires. Nothing makes it LONG: each session claims, merges, ends,
and the fleet survives only while every generation spawns the next. Measured
on `origin/main` 2026-08-29, last 120 merges:

```bash
git log --merges --format='%ct' origin/main -120 |
  awk 'NR>1{d=(prev-$1)/3600; if(d>3) n++} {prev=$1} END{print n+0" of "NR-1}'
```

5 of 119 gaps exceed three hours (longest 32.2h and 24.0h), with 11 to 19
plan files in the tree at each — a full queue, idle.

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
- **If a monitor is ever added**: never judge a session dead from one
  signal. Push time is not liveness in either direction — the handover
  protocol's own rule, and why `/who` exists — so a monitor built on a
  single store reads healthy sessions as stuck and ended ones as working,
  and acts on both. Cross-check a second signal before anything acts on the
  verdict.
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

**Propose them with evidence; never add them on a session's own judgment.**
Declining them was the requester's call and re-taking it is theirs too — a
session that adds a cap because a run looked expensive has decided a
question of money, which the Loop reserves for the human
(`.agents/harness/AGENTS.md`, Decide alone). This is why the budget in
issue 165 is not a number a session may pick.

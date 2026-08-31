# Heartbeat: making the unsupervised fleet long

Fan-out makes the fleet WIDE — one session per free plan. Nothing in it
makes the fleet LONG. Each session claims a plan, merges it, ends. Fleet
survives only while every generation spawns the next. One generation that
fails to spawn ends the run silently: queue stops draining, repo looks
idle rather than broken.

Heartbeat = the clock outside the chain. Scheduled Routine fires a FRESH
session on an interval. Holds nothing in a container, so nothing it needs
can be reclaimed. Re-seeds the fleet whether or not the last generation
finished clean.

This file documents the mechanism. It does NOT create the Routine —
that is an operator action with money attached
(`.agents/harness/AGENTS.md`: stop and ask for money).

## Two halves: `/drain` and the heartbeat

They are not alternatives and neither replaces the other. The chain has two
ways to stop, and each mechanism fixes one.

| | `/drain` | Heartbeat Routine |
| --- | --- | --- |
| Makes | one SESSION long | the FLEET long |
| Stops when | the mode says stop | the operator deletes it |
| Survives its session? | no | yes |
| Costs | nothing | money — operator action |
| Available | now, on command | needs a human decision |

A session drains one item and ends; the next item waits for a human to start
a session. `/drain` is the loop that does not — it re-reads
`./joharness.sh drain` between items and keeps taking the next one. That
removes the gap BETWEEN items inside a session. It does nothing about the gap
after the session, which is what the table above is about, and it must not be
sold as if it did.

The mode still decides everything the command does not. Supervised drains
serially and stops at the queue edge; unsupervised carries the fan-out order
this file already describes and stops only on a dry sweep. Width is therefore
not a setting of its own — asking for fan-out under supervised is asking for
the mode boundary the requirement calls byte-identical.

Measured on `origin/main` 2026-08-29, last 120 merges:

```bash
git log --merges --format='%ct' origin/main -120 |
  awk 'NR>1{d=(prev-$1)/3600; if(d>3) n++} {prev=$1} END{print n+0" of "NR-1}'
```

5 of 119 gaps exceed three hours; the longest are 32.2h and 24.0h. At the
first commit of each of the four longest, the tree carried 18, 18, 19 and 11
plan files and 4 research files. The queue was full the whole time — which is
the shape of failure this file predicted in its opening paragraph, now
counted.

## The one question that separates the five

Does it survive the session that created it? Everything else is detail.

| Mechanism | Survives its creator? | Verdict |
| --- | --- | --- |
| Durable Routine (`create_trigger`, claude-code-remote MCP) | YES — stored server-side, fires a fresh session | **Chosen** |
| Session cron (`CronCreate`) | NO | Rejected |
| Self-scheduling session (`send_later`) | Schedule yes, fleet no — wakes ONE existing session | Rejected |
| Scheduled GitHub Actions workflow | YES — but its pull requests get no CI | Rejected, needs credential |
| External Ralph-style loop | Only while its host is up | Rejected |

### Why each rejected one loses

- **Session cron.** Its own schema settles it: jobs "live only in this
  Claude session — nothing is written to disk, and the job is gone when
  Claude exits", `durable` "has no effect", recurring jobs auto-expire
  after 7 days, and they fire only while that REPL is idle. Same chain,
  same single point of failure.
- **Self-scheduling session.** Careful here — the SCHEDULE does survive:
  `send_later` stores a self-bind Routine (`persist_session: true` in
  `list_triggers`) and its delivery survives container restarts. What does
  not survive is the fleet. It re-enters ONE existing conversation instead
  of seeding a fresh one, so it is the same chain with less width, and a
  fleet of one is not a fleet. Right tool for watching a single pull
  request; wrong one for endurance.
- **GitHub Actions.** Survives fine. Disqualified by a fact this repo
  already wrote down in `.github/workflows/update.yml`: on the workflow's
  own `GITHUB_TOKEN`, "a pull request it opens gets NO ci runs (GitHub
  suppresses workflow-on-workflow events)". Unsupervised merging requires
  green checks (step 7), and checks that never run are never green. Fix is
  a PAT repository secret — a credential decision, humans only.
- **External loop.** Needs a host that stays up. An ephemeral container is
  not one, and adopting it moves the problem to hardware nobody approved.

## Cadence

Hourly floor, measured rather than quoted. `*/5 * * * *` is refused:

    failed to create trigger: cron expression "*/5 * * * *" may fire runs
    as little as 5 minutes apart; the minimum interval is 1 hour (cron
    interval too short)

One hour, and the error names it. The heartbeat is a restart, not a tight
loop: an hour between re-seeds is the mechanism on offer, and a plan
needing faster reaction wants fan-out, not a faster clock.

Hourly or every-N-hours at minute 0 is anchored to the creation minute
server-side, so Routines spread across the hour instead of all firing
at :00.

## What the firing session is told

Fresh session, empty context. The prompt is a complete standalone
instruction — a fresh-session Routine inherits no conversation. It says:
run the Loop. Nothing more is needed, because the hook already prints
queue, claims and wanted tier before the first prompt.

Two cases, and only one of them is this file's. Queue NOT empty: the
session claims and runs, or fans out (below). Queue empty: the session
reaches the edge — and what happens there is the edge rule, not the
heartbeat's business.

It does NOT restate that edge rule. What a session does when the queue is
empty belongs to the requirement's `Satisfied when` and to
`unsupervised-edge-work`, which owns the two edge paths in
`.agents/harness/queue-context.sh`. Copying that rule here would be the second copy the
graph rules forbid, and it is under active revision — the heartbeat only
guarantees a session EXISTS to reach the edge, never what happens there.

## The prompt grants nothing — the repository authorises

Measured 2026-08-31: two sessions spawned into a repo whose committed mode
was unsupervised both stopped in **48 seconds**, blocked and asking for a
human — *"injected task rejected"* and *"suspected prompt injection in
task"*. 0 pull requests, $0.56.

**They were right.** An instruction arriving in a session with no human
present, saying *never ask a human*, *there is no human watching you*,
*merge your own pull requests*, *keep working indefinitely*, is the shape an
injected task has. A session that complies with it unconditionally is the
one misbehaving. The prompt that says "you are authorised" is exactly the
prompt an attacker writes, and no amount of rewording changes that — a
claim cannot be its own evidence.

So a spawn prompt asserts nothing. It **routes**, and points at what the
session can check for itself:

```
./joharness.sh authority
```

That reports where the autonomy claim comes from and reaches a verdict.
Only one source counts: a **merged** `JOHARNESS_MODE` line in
`joharness.conf` — a commit that went through a pull request, in the repo
the session cloned. A marker in a git directory and an exported
`JOHARNESS_MODE` are both the *caller* claiming authority by another route,
which is the thing the session is right to distrust, and both read
UNVERIFIED.

A spawn prompt therefore carries three things and no fourth:

1. **The work**, named. A claim exists only after the spawned session's
   first push, so two sessions started against one queue can both take the
   top plan — the caller names each one's work (PR 154).
2. **`./joharness.sh authority`**, and: if the verdict is not VERIFIABLE,
   stop and say so.
3. **The protocol paths it must not commit under**
   (`./joharness.sh protocol-paths`).

What it must NOT contain, because each is a claim rather than a pointer,
and together they are the refusal's whole trigger:

- "there is no human watching you"
- "never ask a human"
- "this was authorised by <someone>"
- any instruction to keep going that does not come from the Loop itself

The Loop already says what to do at the edge, and the mode already says
whether the Loop runs unattended. A prompt repeating either is adding
assertion where the tree already has fact.

**Tuning the wording until a session stops refusing is not the remedy.** If
a session declines after checking committed evidence, that is its call.
This machinery makes the evidence checkable; it does not exist to make the
check come out a particular way.

## Run a plan, or fan out?

The queue hook already decides and prints it. No judgment to add:

- `N free plans = N parallel sessions. Spawn one per plan, model = its
  tier.` — two or more free plans, so fan out, one session per plan,
  each on the tier its plan names. That line is the queue's answer only
  when the queue proved it; with no `scope:` anywhere it proved nothing,
  and the unsupervised reader is told so below.
- One free plan — run it in this session. Spawning one child to do what
  the firing session can do costs a container for nothing.
- Waves. Same wave = declared scopes disjoint, parallel proven. Never
  spawn across waves in one generation; the hook names the conflict.

Supervised, that line REPORTS. Unsupervised, it ORDERS: the hook names
wave 1's plans and their tiers and says start them now. Wave 1 only — a
later wave conflicts with it on a path the hook prints, so it is the next
generation, not this one. No plan declares `scope:`? Nothing is proved, so
nothing is spawned: claim one, run it here.

Ordered N, fewer claims land? No repair. The claim is a pushed workstream
file, so a plan nobody took is still free and the next generation takes it.
Never re-spawn to "finish" a generation — a second session on a plan whose
claim is merely slow to push is the double-claim the push rule exists to
prevent.

## Firing while the previous fleet is still working

Nothing special happens, by design. The new session reads the queue like
any other: plans already claimed are not free, so it takes what is left or
reaches the edge. No fleet bookkeeping, no run registry — git holds the
state or it is not held.

The failure this leaves open is the one the handover protocol already
names: a session that has claimed but not PUSHED is invisible, so a
heartbeat firing can double-claim it. Mitigation is the existing rule, not
a new store — push the workstream file as soon as work has a name, and
`/who` before touching a branch that overlaps.

## Operator procedure

For the OPERATOR. A session never creates the heartbeat, whatever a plan
says: a recurring job is recurring spend, and spend is the human's
(`.agents/harness/AGENTS.md`). Reading this procedure is not authorisation
to run step 1.

Runnable as written; each step below was run end to end on a throwaway
Routine. Tools are on the claude-code-remote MCP server. Find them by
SEARCH, never by hardcoded name: the server prefix is hashed and unstable
across sessions, so `mcp__Claude_Code_Remote__create_trigger` fails with
"No such tool available" while the same call under the hashed prefix
works. Same trap `/who` hit
(`.agents/docs/handover/README.md`).

1. **Create.** `create_trigger` with `create_new_session_on_fire: true`
   (fresh session per firing — the whole point), a cron expression in
   UTC, and a standalone prompt. Returns `trigger.id` (`trig_...`).
2. **Inspect.** `list_triggers` — `enabled`, `next_run_at`, and `last_run`
   (the most recent run's status; absent when it has never fired).
3. **Pause.** `update_trigger` with `enabled: false`. Verify from
   `list_triggers`, NOT from the update response: on pause the response
   OMITS the `enabled` key rather than showing false, and `next_run_at`
   still shows the old time. Neither means it will fire.
4. **Delete.** `delete_trigger` with the id. Permanent; `update_trigger`
   fixes a bad cron or prompt in place without losing run history.

`fire_trigger` runs one immediately, outside the schedule — the way to
test a heartbeat prompt without waiting an hour.

### The connector trap

A Routine created through `create_trigger` stores NO MCP connectors unless
the calling session can pass them through, and the sessions it fires then
run WITHOUT any `mcp__<server>__*` tool. Measured on the throwaway: the
stored `allowed_tools` came back as `preset:default` plus Bash, Read,
Edit, Write and friends — no `mcp__github__*`.

That breaks unsupervised merging where the environment has no `gh` CLI,
because opening and merging a pull request is exactly a connector call.
The tool's own warning names the remedy: create the Routine from the
claude.ai Routines UI, or from a session that holds the connectors.
Verify before trusting a heartbeat: fire once, and check the fired
session could reach GitHub at all.

## Stop

The operator's veto. Pause with `enabled: false`, or delete.

Proved, not asserted. A one-shot Routine was created for a time seven
minutes out and paused before it. After that moment passed,
`list_triggers` showed it carrying NO `last_run` key at all — it never
ran — beside a live Routine in the same response still reporting
`enabled: true`. Deleting it then dropped it from the listing entirely.

Read `last_run` for this, never `next_run_at`: a paused Routine keeps its
old `next_run_at` and the field goes stale in the past, which reads
alarmingly like a missed firing and is not one. Pausing is enough;
deleting is for when the Routine is finished with.

A human who cannot halt the fleet has no veto, and the harness reserves
veto to the human (`.agents/harness/AGENTS.md`).

## No cap, and the argument for one

The requester was offered a cap on work per run, a halt when `main` is
red, and a ban on sessions spawning sessions, and declined all three on
2026-08-24 (`docs/product/unsupervised-mode.md`, Constraints). That
stands; a decomposing session must not add them back on its own judgment.

Recorded here so the human sees the argument without this file acting on
it: a heartbeat changes the shape of that decision. Fan-out alone is
bounded by the queue — N free plans, N sessions, then the fleet drains.
A clock is unbounded by construction: it re-seeds whether or not the last
generation converged, so a bug that makes generations fail fast turns into
a firing every hour forever rather than one bad run. The lever that closes
this is not a cap on the fleet — it is the Routine's own pause, which is
why the stop procedure above is proved and not merely written.

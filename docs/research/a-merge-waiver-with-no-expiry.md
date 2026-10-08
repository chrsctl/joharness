---
research: a-merge-waiver-with-no-expiry
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/orchestrated.md
---

<!--
A report from a consumer (`chrsctl/gx`), filed by the route
`.claude/commands/upstream-report.md` names. Canonical decides.

Unlike the two nodes in #319, most of this node's consumer-side evidence WAS
re-measured here: `chrsctl/gx`'s `joharness.conf` and the GitHub check runs on
the two pull requests are both readable from this session, and both are quoted
with the ids that re-count them. Only the session records (status, cost,
archive times) are REPORTED and could not be re-taken — marked where used.

Two claims in the finding this node was filed from did NOT survive that check
and are recorded as refuted under `## Findings`, because they are the reason
the fix proposed with it is refused here.
-->

## Question

Does `JOHARNESS_CHECKS=local` expire — does any harness rule or reading tell a
session that the infrastructure failure the waiver was set for has lifted — or
does each manager resolve a lapsed waiver alone at the finish line?

## Echo

`JOHARNESS_CHECKS=local` is an operator's waiver of step 7's first merge
condition, set because waiting for Actions was waiting for nothing. A waiver
set against a condition outlives that condition: runners come back. What I am
asking is whether the harness holds the key as a standing fact about the
repository, or as a reading of something — because if it is the former, then
the day runners return, every manager meets a contradiction (my conf says do
not wait; Actions is running and reporting) and resolves it privately, at the
most expensive point in the Loop.

Not asking whether a manager should wait for Actions. That is what the finding
this node came from asked, and the measurement below refuses its answer: on
one of the two heads, the job the local checks cannot run was RED, so "never
wait under local" would have merged over it.

## Sweep

`goal-directed` — enough to establish whether any reader of the key consults
anything but its value, and whether the two proposed fixes are safe. Not a
survey of step 7's conditions, and not a proposal for a new knob.

## What would settle it

- **A reader of the key that consults anything but its string.** Enumerate
  every reader in the source. If all of them branch on the value alone, there
  is no expiry and the answer is no.
- **Whether the naive fix is safe.** Read what the Actions run on each of the
  two heads actually concluded. If any job was red where `ci` and `verify` are
  green, then "under local the manager never waits" is refused by measurement
  rather than by argument, and this question is about the waiver and not about
  the wait.
- **Where a manager is told what a live run means under `local`.** Enumerate
  the places that state the no-wait rule and their arrival order relative to
  the wait. If a qualified copy arrives FIRST and lost anyway, the fix shape
  that #303 proposes for its own instance does not generalise, and saying so
  is part of the answer.
- **Whether this is #266 again.** #266 is a manager stale in the opposite
  direction — blocked on a cause `local` had already lifted. If the mechanism
  is the same with the arrow reversed, this appends to that record rather than
  opening a new front.

## Method

Run on this checkout at `832f5fdd`:

    grep -rn "JOHARNESS_CHECKS" .agents/ .claude/ joharness.sh joharness.conf .github/
    sed -n '215,245p' joharness.sh
    grep -n "gh run\|actions_list\|api/runs\|check-runs\|check_runs" joharness.sh .agents/harness/*.sh
    sed -n '150,160p' .agents/harness/AGENTS.md
    sed -n '150,160p' .claude/commands/manage.md
    grep -ci "JOHARNESS_CHECKS" .claude/commands/manage.md
    grep -ci "actions" .claude/commands/manage.md
    sed -n '9195,9208p' joharness.sh
    sed -n '6482,6502p' joharness.sh
    sed -n '137,195p' .claude/commands/orchestrate.md
    sed -n '694,712p' .agents/docs/orchestrated.md
    sed -n '40,122p' .github/workflows/ci.yml
    sed -n '49p' .agents/scripts/conf-keys.sh

Read from the consumer, by the GitHub API, 2026-10-08 (quoted as the MCP
calls that produced them; the ids re-count them for anyone):

    get_file_contents  chrsctl/gx  joharness.conf  refs/heads/main
    pull_request_read  get_check_runs  chrsctl/gx  495
    pull_request_read  get_check_runs  chrsctl/gx  498
    list_issues  chrsctl/joharness  OPEN

## Findings

- **No reader of the key consults anything but its string, so there is no
  expiry.** `checks_mode()` is one line — `${JOHARNESS_CHECKS:-$(conf_get
  JOHARNESS_CHECKS)}` (`joharness.sh:231`) — and `checks_local()` is a `case`
  over three outcomes, `local`, `''|github`, and a warn-and-fail-closed default
  (`:233-242`). Those two are the whole of it: every other hit in the
  repository is a selftest, a printf, a comment, or the workflow's own
  variable. And nothing anywhere reads Actions at all —
  `grep -n "gh run\|actions_list\|api/runs\|check-runs\|check_runs" joharness.sh
  .agents/harness/*.sh` returns NOTHING. So the harness cannot notice that the
  condition the waiver was set for has lifted, in either direction, by
  construction.

- **The waiver's own stated revert test had been met, and nothing evaluates
  it.** `chrsctl/gx`'s `joharness.conf` on `main`, read here, carries
  `JOHARNESS_CHECKS=local` with its reason — *"Set to local 2026-09-16,
  requester's instruction, with GitHub unable to allocate a runner
  account-wide: the last 15 completed runs in this repository had ZERO
  successes since 2026-09-13"* — and its own expiry: *"Revert to github once a
  runner allocates. That is a measurement, not a calendar: one completed run
  with a green job is the whole test."* That test was satisfied on both heads
  below: job `harness` concluded `success` at 2026-10-08T06:31:04Z (run
  37738004391) and again at 07:24:45Z (run 37743221243). The conf still said
  `local`. Nothing reads that sentence — and nothing could: `joharness.conf`
  never syncs and a consumer may carry no line for a key at all
  (`.agents/docs/consumer-repos.md:240-252`, which measures exactly that:
  `grep -c 'JOHARNESS_CHECKS' joharness.conf` is 0 in one synced consumer).

- **REFUTED, and this is why the fix filed with this finding is not carried:
  one of the two runs was RED on the job the local checks cannot run.** The
  finding stated that on both pull requests *"every required check was green or
  superseded"*. Counted from the API, 2026-10-08:

  | head | job | conclusion | completed |
  | --- | --- | --- | --- |
  | gx #495, run 37738004391 | `harness` | success | 06:31:04Z |
  | | `license-gate` | success | 06:31:54Z |
  | | `schema-sync` | success | 06:32:06Z |
  | | `acceptance` | success | 06:33:26Z |
  | | `crm` | cancelled | 07:02:13Z |
  | gx #498, run 37743221243 | `harness` | success | 07:24:45Z |
  | | `license-gate` | success | 07:26:10Z |
  | | `schema-sync` | success | 07:26:21Z |
  | | `acceptance` | success | 07:27:39Z |
  | | **`crm`** | **failure** | **07:40:34Z** |

  On #495 the claim holds. On #498 `crm` concluded `failure`. And `crm` is
  precisely the job a local green does not cover — gx's own conf says so in
  the same comment: *"What a local green does NOT cover, and `finish` reprints
  it on every run: any job in .github/workflows/ that `ci` does not run. The
  big one here is `crm` — the Postgres acceptance suite, the largest body of
  coverage in this repository — which the free offline loop cannot reach at
  all (ADR 0039)."* So a rule saying "under `local` the manager never waits for
  an Actions run" would, applied to #498, have merged over the largest test
  suite in that repository failing. The manager's wait was the only behaviour
  that could see it.

- **The wait was still wrong on #495, by 16 seconds.** REPORTED: the manager
  for `crm-ui-hints-queue-and-palette` went IDLE and disconnected at
  06:31:38Z with `post_turn_summary` *"CI in progress: harness passed,
  license-gate still running"*. Measured here: `license-gate` concluded
  `success` at 06:31:54Z — **16 seconds later** — and every job but `crm` was
  green by 06:33:26Z, 1m48s after it fell asleep. REPORTED: `cost_usd` and
  `updated_at` never moved again, `interrupt_session` at 07:24Z did not wake
  it, and it was archived at 07:39Z — 67 minutes — and respawned with a
  finish-only prompt. So the summary was accurate when written and stale
  within the minute, and the session had no turn in which to re-read it.

- **REFUTED: the orchestrator's health table does not treat this as the
  45-minute stall, and already reaches it faster than the row proposed for
  it.** The finding asks for a new row *"rather than the generic 45-minute
  stall"*. Read in the order `.claude/commands/orchestrate.md:139` prescribes
  — *"Read the rows IN ORDER and act on the FIRST that matches"* — an IDLE
  manager with an unmerged branch matches `:187`, whose push-age cell is
  **`any`**: *"NOT gone — IDLE is between turns. NUDGE, exactly as the stall
  row does ... Spawn nothing this pass."* `JOHARNESS_STALL_MINUTES` (45) never
  enters it. The next row, `:188`, respawns when head and `status_detail` are
  both unchanged across that nudge. At `JOHARNESS_HEALTH_MINUTES` = 10
  (`.agents/docs/orchestrated.md:331`) that is a respawn roughly 20 minutes
  after the session goes quiet, with no nudge channel needed — `:174` states
  the no-messaging path explicitly, *"send nothing and still write the ledger
  entry — the next pass then reads the row below and kills"*. So the 67
  minutes measures an orchestrator that did not read `:187`, not a table that
  waits 45. A new row keyed on "IDLE after the PR opened" would replace a row
  that already fires sooner.

- **One file does state a condition the repository had replaced, and it is the
  manager's own rules.** `.claude/commands/manage.md:153` is the whole of what
  a manager is told about finishing: *"Step 7 as written: green checks, 0
  behind fresh `origin/main`, `./joharness.sh finish` green"*.
  `grep -ci "JOHARNESS_CHECKS" .claude/commands/manage.md` returns **0**, and
  `grep -ci "actions"` returns **0**: in 222 lines, the file a manager reads as
  its own rules never names the key that replaces the first item on that list,
  nor the system it would be waiting for. It also orders them: "green checks"
  is first and `finish` green is third, so a literal reader waits before
  running the one command whose output would correct it.

- **The correction exists in three places, and in this instance the one that
  arrived FIRST lost.** `.agents/harness/AGENTS.md:153-157` carries the clause
  — *"`JOHARNESS_CHECKS=local` (session start says so) replaces the FIRST
  condition and no other: `finish` runs `ci` and `verify` itself instead of
  waiting for Actions, and there is no run to read for the layer then"* — and
  the session-start banner fires under `local` (`joharness.sh:9201-9206`):
  *"Step 7 does NOT wait for GitHub Actions here."* Its own source comment
  states the cost this question is about, and states it as a bet already
  placed (`:9197-9199`): *"a session that learns at step 7 that it did not have
  to wait for Actions has already waited once. Silent under the default."*
  `finish` prints it a third time (`:6500-6501`). gx's conf is `local`, so the
  banner fired for both managers. Both waited anyway. **This is the inverse of
  #303 and it matters for #303's fix:** there the unqualified copy arrives
  first and the qualified one is 636 lines in, and the fix is to qualify the
  copy that lands first. Here the qualified copies land first — hook banner,
  then `AGENTS.md` — and the unqualified one lands last and nearest the work,
  on invocation of `/manage`. Nearest-the-work won, twice in 54 minutes. So
  "qualify the first copy" is not a general fix for this class.

- **A secondary mismatch, scoped narrowly because it is a source comment and
  not an instruction.** `joharness.sh:223-225` describes `local` as
  *"`finish` runs the same checks here, on this head"*. In gx they are not the
  same checks: `ci` does not run `crm`, which is the measurement two findings
  up. The user-facing paths are careful where this comment is not —
  `conf-keys.sh:49` names *"ci and verify"* rather than "the same checks",
  `AGENTS.md:156` says `finish` *"names what it cannot cover, in its own
  output"*, and it does. So the overstatement is one comment deep and reaches
  no session that has not opened `joharness.sh`; it is recorded because the
  phrase is the seed of the misreading the rest of this node measures.

- **This is #266 with the arrow reversed, which is the reason to file it
  rather than append it.** `.agents/docs/orchestrated.md:704-708` records
  #266: a manager *"sat `blocked` 11h18m on a cause `JOHARNESS_CHECKS=local`
  had lifted 8h47m before its session was created"* — a session stale against
  a conf that had already moved. Here the conf is stale against the
  infrastructure. Same mechanism, opposite direction, and the answer recorded
  for #266 does not reach this one: *"`JOHARNESS_IDLE_ANALYSIS` answers that
  by explaining, not by deciding — the conf line stays the human's."* An
  analyst explains a session; nothing explains a conf line.

## Consequence for the queue

**Neither fix proposed with this finding is carried, and the refusals are the
contribution.** (1) "Under `JOHARNESS_CHECKS=local` the manager never waits
for an Actions run and never ends its turn between opening the PR and
merging" — the first half is refused by #498's red `crm`: the Actions run
carries coverage `finish` cannot produce, and gx's conf says so in advance. The
second half stands on its own and is the cheap, safe part. (2) A health row for
"IDLE + disconnected after the PR opened" — refused: `orchestrate.md:187`
already matches at push age `any` and respawns one pass later, which is sooner
than the proposed row and needs no change. Both are the shape the route warns
about: *never relax a guard that just caught you*, and here the guard that
caught the fleet was the manager's own wait.

What a plan from this node would change, cheapest first:

- **`manage.md:153` stops restating step 7's first condition.** Name the
  condition as conf-dependent, or drop the restatement and point at step 7,
  which already carries the clause. The measurement is that the restatement
  nearest the work beat two qualified copies that arrived earlier, so the fix
  is to stop having two copies rather than to qualify the third. One line. It
  owes nothing to `.agents/docs/`, and it lands in protocol text — named, not
  written, below.
- **The same section says what a live run MEANS under `local`.** Not "do not
  wait", which #498 refutes, but the true statement: the run is not step 7's
  gate, and a job `ci` does not run is information `finish` cannot give you.
  That is a manager deciding with both readings in hand instead of choosing
  one blind.
- **Whether a waiver should carry an expiry at all is the human's, and this
  node does not assert it.** The measurement says only that nothing evaluates
  the revert test the operator wrote, and that two managers paid for the gap.
  The `#266` answer — explain, never decide, the conf line stays the human's —
  is the precedent, and an explaining reader (a line in `dispatch`, or the
  analyst's remit) is the shape that fits it. A gate that flipped the key
  itself would be a session rewriting protocol text, which nothing permits.

What the answer owes before any of it is written: whether gx's managers
actually read the session-start banner. The banner fires on `checks_local()`,
which is true there, but a session's own context is not readable from this
repository (#267), so "both were told and both waited" is an inference from
the conf and the hook, not an observation of either session. If they were not
told — a hook that did not run, a resumed container — then the first bullet
above is the whole finding and the ordering argument against #303's fix shape
falls.

## Verification

Second context: `.claude/agents/verifier.md` at opus, which re-derived the
harness claims from the cited files rather than from the quotations above, and
was told which claims are consumer-side.

- **No reader of the key consults anything but its value; nothing reads
  Actions** — GROUNDED. `checks_mode()`/`checks_local()` enumerated, and the
  Actions grep's empty result reproduced.
- **gx's conf is `local` and carries its own revert test** — GROUNDED, read
  from `chrsctl/gx@main` in this session, not reported.
- **`crm` was `failure` on gx #498 and `cancelled` on #495** — GROUNDED, from
  the check-run API with run and job ids that re-count it. This refutes the
  filed finding's "every required check was green or superseded" and is the
  reason fix (1) is refused.
- **`orchestrate.md:187` matches at push age `any`, ahead of any stall
  threshold** — GROUNDED; rows read in the `:139` order. This refutes the
  filed finding's premise that the 45-minute stall applied.
- **`manage.md` names the key 0 times and "actions" 0 times; `:153` orders
  checks before `finish`** — GROUNDED, counted.
- **The banner, the AGENTS.md clause and `finish`'s output all state the
  no-wait rule** — GROUNDED, verbatim with line numbers.
- **The arrival order (banner and AGENTS.md before `manage.md`)** — WEAK. The
  hook runs at session start and `/manage` is invoked after it, which is the
  mechanism; that both gx sessions experienced it in that order is not
  observable here (#267), and the node says so.
- **The session records: IDLE times, `post_turn_summary` text, frozen
  `cost_usd`, the 07:24Z interrupt, the 07:39Z archive and the respawn** —
  WEAK, REPORTED. No control-plane tool in a second context, and the standing
  limit #267 records. The harness-side findings do not rest on them: the key
  has no expiry, `manage.md` omits it, and `:187` already fires, whether or
  not these two sessions behaved as reported.

## Graduates to

`.agents/docs/orchestrated.md` — it already carries this question's mirror at
`:698-716`: the runner outage, the fleet splitting on step 7's first
condition, and #266's manager stale against a conf that had moved. The answer
to a conf stale against the infrastructure belongs beside that paragraph, not
in a rule line alone, because the reasoning is the part that transfers: a
waiver is set against a condition, the condition lifts without telling
anybody, and the harness holds the waiver as a fact about the repository. The
next reader also needs the two refusals — that "never wait" merges over a
suite `ci` cannot run, and that `:187` already fires — or they will be
proposed again.

Named, not written: the fix for the first two bullets lands in
`.claude/commands/manage.md`, which is protocol text
(`./joharness.sh protocol-paths`). A plan touching it is supervised only, and
this node does not propose it.

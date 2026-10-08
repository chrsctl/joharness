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

Unlike the two nodes in #319, most of this node's consumer-side evidence was
re-measured — twice, in two contexts: `chrsctl/gx`'s `joharness.conf` and the
GitHub check runs on two of its pull requests are readable by API from here,
and both are quoted with the ids that re-count them. Only the SESSION RECORDS
(status, `status_bucket`, cost, interrupt and archive times) are REPORTED and
could not be re-taken — the standing limit #267 records. They are marked
REPORTED at each use, and no harness-side finding rests on one.

Two claims in the finding this node was filed from did NOT survive that check.
They are recorded as refuted under `## Findings`, because they are the reason
the fix proposed with the finding is refused rather than carried.
-->

## Question

Does any reader of `JOHARNESS_CHECKS` consult anything but the key's value, so
that a `local` waiver set against a runner outage can notice the outage has
lifted?

## Echo

`JOHARNESS_CHECKS=local` is an operator's waiver of step 7's first merge
condition, set in a consumer because waiting for Actions was waiting for
nothing. A waiver set against a condition outlives that condition: runners come
back. What I am asking is narrow and answerable from source — whether the key
is held as a standing fact about the repository, or as a reading of something.
What rests on the answer is what a manager meets at step 7 on the day runners
return: a conf that says do not wait, and an Actions run that is live and
reporting.

Not asking whether a manager should wait for Actions. That is what the finding
this node came from asked, and the measurement below refuses its answer: on one
of the two heads, the job the local checks cannot run was RED, so "never wait
under `local`" would have merged over it.

Also not asking why two managers behaved as they did. That is a claim about
sessions, which cannot be settled here (#267). The behaviour is the cost
evidence; the question is about the key.

## Sweep

`goal-directed` — enough to enumerate every reader of the key and establish
whether the two fixes proposed with the finding are safe. Not a survey of step
7's conditions, and not a proposal for a new knob.

## What would settle it

- **A reader that consults anything but the value.** Enumerate every reader in
  the repository, including generic ones a literal-string grep would miss. If
  all of them branch on the string alone, there is no expiry and the answer is
  no.
- **Whether anything in the harness reads infrastructure at all.** If no code
  path reaches Actions or the network, the answer is no a fortiori and no
  wording change can alter it.
- **Whether the naive fix is safe.** Read what the Actions run on each of the
  two heads actually concluded. If any job was red where `ci` and `verify` are
  green, then "under `local` the manager never waits" is refused by
  measurement rather than by argument.
- **Whether this is #266 again.** #266 is the opposite staleness — a manager
  blocked on a cause `local` had already lifted. If the mechanism built for
  #266 reaches this direction too, there is nothing to ask. Settled by reading
  what that mechanism consults.

## Method

Run on this checkout at `832f5fdd`:

    grep -rn "JOHARNESS_CHECKS" .agents/ .claude/ joharness.sh joharness.conf .github/
    grep -n "checks_local" joharness.sh
    sed -n '215,245p' joharness.sh
    grep -n "gh run\|actions_list\|api/runs\|check-runs\|check_runs" joharness.sh .agents/harness/*.sh
    grep -rn "curl\|wget\|gh api\|gh pr checks\|workflow_run\|statusCheckRollup" joharness.sh .agents/harness/*.sh .agents/scripts/*.sh
    sed -n '4803,4814p;4924,4964p' joharness.sh
    grep -n "JOHARNESS_IDLE_ANALYSIS" .agents/scripts/conf-keys.sh joharness.sh
    sed -n '150,160p' .agents/harness/AGENTS.md
    sed -n '5,8p;126p;150,159p' .claude/commands/manage.md
    grep -ci "JOHARNESS_CHECKS" .claude/commands/manage.md
    grep -ci "actions" .claude/commands/manage.md .claude/commands/orchestrate.md
    sed -n '9195,9208p;6498,6502p;8012p' joharness.sh
    sed -n '99,101p;137,195p;253,256p' .claude/commands/orchestrate.md
    sed -n '331p;694,709p' .agents/docs/orchestrated.md
    sed -n '240,258p' .agents/docs/consumer-repos.md
    sed -n '49p;54p' .agents/scripts/conf-keys.sh
    sed -n '110,122p' .github/workflows/ci.yml

Read from the consumer by the GitHub API, 2026-10-08, in both contexts
independently (quoted as the calls that produced them; the ids re-count them):

    get_file_contents  chrsctl/gx  joharness.conf  refs/heads/main
    gh api repos/chrsctl/gx/actions/runs/37738004391/jobs
    gh api repos/chrsctl/gx/actions/runs/37743221243/jobs
    list_issues  chrsctl/joharness  OPEN

## Findings

- **Two readers of the key, both branching on the string alone.**
  `checks_mode()` is one line — `${JOHARNESS_CHECKS:-$(conf_get
  JOHARNESS_CHECKS)}` (`joharness.sh:231`) — and `checks_local()` is a `case`
  over `local`, `''|github`, and a warn-and-fail-closed default
  (`:233-241`). `grep -n "checks_local" joharness.sh` returns exactly three
  lines: the definition and its two callers, `:6716` (inside the `finish`
  checks gate) and `:9200` (the session-start banner). Neither consults
  anything but the value. `.agents/scripts/bootstrap-consumer.sh:157,782` is a
  seeder, not a reader — it decides what a NEW consumer's conf says.

- **Nothing in the harness reads infrastructure at all, so no expiry is
  possible by construction.** `grep -n "gh run\|actions_list\|api/runs\|
  check-runs\|check_runs" joharness.sh .agents/harness/*.sh` returns NOTHING,
  rc 1. Widened in the second context to `gh api|gh pr checks|gh workflow|
  workflow_run|conclusion|statusCheckRollup|check[-_ ]?suite|actions/runs`:
  three incidental hits on the English word "conclusion"
  (`joharness.sh:1724`, `:6076`, `:9289`) and nothing else. Widened again to
  any network tool: **`curl`, `wget` and `gh` appear nowhere in
  `joharness.sh`**, and among `.agents/harness/*.sh` and
  `.agents/scripts/*.sh` only `pretool-bash-guard.sh` matches, on its own
  pattern text. So the answer to the question is **no**, and it is not a
  wording defect: there is no code path by which the key could notice
  anything.

- **One reader DOES consult more than a value, it was built for this exact
  key, and what it reads is git — never infrastructure.** `analysis_one` reads
  `joharness.conf` on TWO refs (`origin/<branch>` and `origin/main`), prints
  the repo's current answer for every conditional row as `conf now :`
  (`joharness.sh:4938-4959`) and every divergence as `conf diff : <key> — this
  branch <bval>, origin/<base> <mval>` (`:4961-4964`); `analysis_conf_moves`
  (`:4803-4814`) reads `git log -- joharness.conf` for keys changed since the
  claim was restated. The comment over it names the incident it was built for,
  and the key (`:4941-4944`): *"This is the line #266 needed and neither
  mechanical signal below would have produced. There,
  `JOHARNESS_CHECKS=local` landed on the base branch 8h47m BEFORE the session
  was created, and the branch carried the line: no key differed, and nothing
  changed after the claim was restated."* So canonical has already accepted the
  explain-don't-decide shape **for this key** — and built it to read conf
  refs and commit times, which answers "has the conf moved?" and can never
  answer "has the infrastructure moved?". It is also off by default:
  `JOHARNESS_IDLE_ANALYSIS` defaults to `off` (`conf-keys.sh:54`).

- **The waiver's own stated revert test had been met, and nothing evaluates
  it.** `chrsctl/gx`'s `joharness.conf` on `main`, read here and re-read in the
  second context, carries `JOHARNESS_CHECKS=local` with its reason — *"Set to
  local 2026-09-16, requester's instruction, with GitHub unable to allocate a
  runner account-wide: the last 15 completed runs in this repository had ZERO
  successes since 2026-09-13"* — and its own expiry: *"Revert to github once a
  runner allocates. That is a measurement, not a calendar: one completed run
  with a green job is the whole test."* That test was satisfied on both heads
  below: job `harness` concluded `success` at 2026-10-08T06:31:04Z (run
  37738004391) and again at 07:24:45Z (run 37743221243). The conf still said
  `local`. Nothing reads that sentence, and nothing could: `joharness.conf`
  never syncs, a consumer keeps whatever comment text it was seeded with, and
  one may carry no line for a key at all — `.agents/docs/consumer-repos.md`
  measures exactly that, `grep -c 'JOHARNESS_CHECKS' joharness.conf` is **0**
  in one synced consumer (`:256-257`; the never-syncs rule and the no-line
  case are at `:240-246`).

- **A second surface with the same shape, in the other home of the key.**
  `.github/workflows/ci.yml:113-116`: *"A convention, not a mechanism: nothing
  stops a session setting this variable — it is in no protocol path and no gate
  reads it. It is a human's switch because a session cannot see it, not because
  anything forbids one touching it."* So neither home of the key is read by
  anything that could time it out.

- **REFUTED, and this is why the fix filed with this finding is not carried:
  one of the two runs was RED on the job the local checks cannot run.** The
  finding stated that on both pull requests *"every required check was green or
  superseded"*. Counted from the jobs API in both contexts, 2026-10-08:

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

  On #495 the claim holds. On #498 `crm` concluded `failure`, and `crm` is
  precisely the job a local green cannot cover — gx's conf says so in the same
  comment: *"What a local green does NOT cover, and `finish` reprints it on
  every run: any job in .github/workflows/ that `ci` does not run. The big one
  here is `crm` — the Postgres acceptance suite, the largest body of coverage
  in this repository — which the free offline loop cannot reach at all (ADR
  0039)."* So a rule saying "under `local` the manager never waits for an
  Actions run" would, applied to #498, have merged over the largest test suite
  in that repository failing. The wait was the only behaviour that could see it.

- **On #495 the wait was still wrong, by 16 seconds.** REPORTED: the manager
  for `crm-ui-hints-queue-and-palette` went IDLE and disconnected at 06:31:38Z
  with `post_turn_summary` *"CI in progress: harness passed, license-gate still
  running"*; `cost_usd` and `updated_at` never moved again;
  `interrupt_session` at 07:24Z did not wake it; archived 07:39Z, 67 minutes,
  and respawned with a finish-only prompt. Measured here: `license-gate`
  concluded `success` at 06:31:54Z — **16 seconds later** — and every job but
  `crm` was green by 06:33:26Z, 1m48s after it fell asleep. So the summary was
  accurate when written and stale within the minute, and the session had no
  turn in which to re-read it.

- **REFUTED: the 45-minute stall never applied, and the health table already
  reaches this faster than the row proposed for it.** The finding asks for a
  new row *"rather than the generic 45-minute stall"*. Read in the order
  `.claude/commands/orchestrate.md:139` prescribes — *"Read the rows IN ORDER
  and act on the FIRST that matches"* — **no non-RUNNING row carries a push-age
  threshold at all**, and every branch an IDLE manager with an unmerged,
  claimed branch can take fires at push age `any`: `:187` nudges (*"NOT gone —
  IDLE is between turns. NUDGE, exactly as the stall row does … Spawn nothing
  this pass."*) and `:188` respawns next pass; or, if the record's
  `status_bucket` is FAILED, `:179` records and `:180` archives then respawns.
  `JOHARNESS_STALL_MINUTES` (45) enters none of them, and the health pass is
  not gated on it (`:99-101`, *"Health pass — before any spawn / For every
  manager in flight"*). At `JOHARNESS_HEALTH_MINUTES` = 10 — the counted
  default, `joharness.sh:8012`, `num_knob JOHARNESS_HEALTH_MINUTES 10`, and the
  knob table at `.agents/docs/orchestrated.md:331` — that is a respawn **10 to
  20 minutes** after the session goes quiet. "disconnected" does not change the
  reading: `orchestrate.md:253-256` says `connection_status` moving
  connected→disconnected *"is not a signal of its own"*, measured on a healthy
  IDLE row. So the reported 67 minutes measures an orchestrator that did not
  work its own rows, not a table that waits 45, and a new row would replace one
  that already fires sooner. WHICH row applied is REPORTED-dependent —
  `status_bucket` is a control-plane field unreadable here (#267) — but the
  refutation does not turn on it: every branch fires at `any`.

- **What survives on the manager's side is thinner than the finding claimed,
  and is a condensation rather than an omission.** `.claude/commands/manage.md`
  names `JOHARNESS_CHECKS` **0** times and "actions" **0** times in 222 lines
  (counted; `orchestrate.md` is also 0 for "actions"), and `:153-154` is the
  only restatement of step 7's conditions in either command file: *"Step 7 as
  written: green checks, 0 behind fresh `origin/main`, `./joharness.sh finish`
  green, retire the plan file and the workstream file in the last commit before
  the pull request, exit."* It orders them, and the order is the cost: "green
  checks" is first, `./joharness.sh finish` is third, and `finish` is the one
  command whose output states the rule (`joharness.sh:6500-6501`, *"No wait for
  Actions — these run here, on this head"*) — so a literal reader waits before
  running the thing that would correct it. But the condition is **qualified by
  reference, not unstated**: the same line says *"Step 7 as written"*, `:5-8`
  declares *"The Loop (`.agents/harness/AGENTS.md`), unchanged … it removes
  nothing"*, and `:126` sends the manager back to `AGENTS.md` for step 5. An
  earlier draft of this node called `:153` *"the whole of what a manager is
  told about finishing"*; that is refuted by its own file and is withdrawn.
  The defect, stated at the strength the source supports: a conf-dependent
  condition is condensed into an unconditional noun phrase, placed first, in
  the file nearest the work.

- **The correction exists in three places, two of which arrive before the
  work.** `.agents/harness/AGENTS.md:153-157` carries the clause —
  *"`JOHARNESS_CHECKS=local` (session start says so) replaces the FIRST
  condition and no other: `finish` runs `ci` and `verify` itself instead of
  waiting for Actions, and there is no run to read for the layer then"* — and
  the session-start banner fires under `local` (`joharness.sh:9201-9206`):
  *"Step 7 does NOT wait for GitHub Actions here."* The banner is not
  mode-gated: it sits at the top level of `cmd_session_start` (`:9200`), before
  the `orchestrated` branch at `:9214`. Its own source comment states the cost
  this question is about, as a bet already placed (`:9197-9199`): *"a session
  that learns at step 7 that it did not have to wait for Actions has already
  waited once. Silent under the default, which is the mode the loaded rules
  already describe."* gx's conf is `local`, so the banner fired. **Bearing on
  #303:** that issue's instance is a command `description:` surfaced before any
  file is opened, with the qualifier 636 lines into the body, and its fix is to
  qualify the copy that lands first. Here the order is reversed — hook banner
  and `AGENTS.md` load before the first prompt, `/manage`'s body arrives with
  it — so the qualified copies land first and the condensed one lands nearest
  the work. Stated at the strength the evidence supports: the ARRIVAL ORDER is
  verified from `.claude/settings.json` and the pre-prompt chain; that the
  condensed copy is WHY the managers waited is a claim about sessions and is
  not observable here (#267). So this does not show #303's fix shape to be
  wrong — it shows it would not have been sufficient in a case where the
  first-landing copy was already qualified.

- **A secondary mismatch, scoped to one comment.** `joharness.sh:224` describes
  `local` as *"`finish` runs the same checks here, on this head"*. In gx they
  are not the same checks: `ci` does not run `crm`. The user-facing paths are
  careful where this comment is not — `conf-keys.sh:49` says *"runs ci and
  verify here"*, `AGENTS.md:156` says `finish` *"names what it cannot cover, in
  its own output"*, and it does. gx's own seeded conf comment is careful too,
  naming `ci` and `verify` rather than "the same checks", so the overstatement
  reaches a gx session only through the synced `joharness.sh`. Recorded because
  the phrase is the seed of the misreading, not because it misled anyone here.

- **This is #266 with the arrow reversed, which is why it is filed rather than
  appended.** `.agents/docs/orchestrated.md:704-709` records #266 (now closed):
  a manager *"sat `blocked` 11h18m on a cause `JOHARNESS_CHECKS=local` had
  lifted 8h47m before its session was created"* — a session stale against a
  conf that had already moved, answered by *"`JOHARNESS_IDLE_ANALYSIS` answers
  that by explaining, not by deciding — the conf line stays the human's."* Here
  the conf is stale against the infrastructure. Same key, same class, opposite
  direction — and the mechanism built for #266 reads conf refs and commit
  times, so it cannot reach this direction at all.

## Consequence for the queue

**Neither fix proposed with this finding is carried, and the refusals are the
contribution.** (1) "Under `JOHARNESS_CHECKS=local` the manager never waits for
an Actions run and never ends its turn between opening the PR and merging" —
the first half is refused by #498's red `crm`: the Actions run carries coverage
`finish` cannot produce, and gx's conf says so in advance. The second half
stands on its own and is the cheap, safe part. (2) A health row for "IDLE +
disconnected after the PR opened" — refused: every branch an IDLE manager can
take already fires at push age `any`, 10 to 20 minutes out, so the row would
replace one that fires sooner. Both are the shape the route warns about at
`.claude/commands/upstream-report.md:60` — *"Never relax a guard that just
caught you"* — and here the guard that caught the fleet was the manager's own
wait.

What a plan from this node would change, cheapest first:

- **`manage.md:153-154` stops condensing a conf-dependent condition into an
  unconditional one.** Either drop "green checks" from the list and let *"Step
  7 as written"* carry it, or write the condition as conf-dependent. One line.
  It is a wording fix and the node claims nothing more for it: the measurement
  is the ordering (condensed copy first, `finish` third, nearest the work), not
  that it caused the two waits.
- **The same section says what a live run MEANS under `local`.** Not "do not
  wait", which #498 refutes, but the true statement: the run is not step 7's
  gate, and a job `ci` does not run is information `finish` cannot give you.
  That is a manager deciding with both readings in hand instead of one blind.
- **Whether the waiver should expire is the human's, and this node asserts
  nothing about it.** What is measured is that nothing evaluates the revert
  test the operator wrote, that no harness code path reads infrastructure, and
  that the reader built for this key reads git only. The #266 precedent —
  explain, never decide, the conf line stays the human's — is the shape that
  fits, and `analysis_one`'s `conf now :` line is where such an explanation
  would go: it already prints the repo's current answer for this key beside a
  parked manager's prose. A gate that flipped the key itself would be a session
  rewriting protocol text, which nothing permits.

What the answer owes before any of it is written: nothing from this repository
— the question as asked is closed by the first two findings. What a FIX owes is
the session layer this node cannot reach (#267): whether a manager that was
told at session start still waited, and on what reading. Without that, the
first two bullets are wording improvements with a measured cost beside them,
not a demonstrated cause.

## Verification

Second context: `.claude/agents/verifier.md` at opus, which re-derived every
harness claim from the cited file rather than from the quotations here, walked
the health-table rows itself in the prescribed order, re-counted the greps, and
— having a REST route — independently re-took both consumer measurements. It
refuted two claims and corrected six citations; all are fixed above and named
here, because a reader deciding whether to trust this node should see what did
not survive.

- **No reader consults anything but the value; nothing reads infrastructure** —
  GROUNDED, and strengthened: the second context found `curl`, `wget` and `gh`
  absent from `joharness.sh` entirely. CORRECTED: `checks_local()` ends at
  `:241`, not `:242`.
- **`analysis_one` reads more than a value** — REFUTED the draft, and this was
  the most valuable catch. The draft closed with *"An analyst explains a
  session; nothing explains a conf line"*. `analysis_one` reads the key on two
  refs plus conf commit times and exists, by its own comment, for #266 and this
  key. The finding is rewritten to the accurate and narrower claim — what it
  reads is git, never infrastructure — and the proposal now says the remedy
  partly exists rather than that none does. The draft's grep missed it because
  the reader is generic over conf keys.
- **`manage.md:153-154` as "the whole of what a manager is told about
  finishing"** — REFUTED by its own file: `:5-8`, `:126`, and the line's own
  *"Step 7 as written"*. Load-bearing, because it was the premise of both the
  #303 inversion and the first proposed fix; both are restated above at the
  strength the source supports. CORRECTED: the quotation spans `:153-154` and
  the draft cut mid-sentence without ellipsis.
- **`manage.md` counts: 0, 0, 222 lines** — GROUNDED, re-counted
  independently. Strengthened: `orchestrate.md` is also 0 for "actions", and
  `:153-154` is the only such restatement in either command file.
- **`crm` was `failure` on gx #498 and `cancelled` on #495; every timestamp in
  the table; the 16s, 1m48s and 67m intervals** — GROUNDED in both contexts
  from the jobs API, with run and job ids that re-count it. This refutes the
  filed finding's "every required check was green or superseded" and is why
  fix (1) is refused.
- **gx's conf is `local` and carries its own revert test** — GROUNDED, read
  from `chrsctl/gx@main` in both contexts, not reported. The second context
  added that gx's seeded comment does not carry canonical's "the same checks"
  phrase, which narrows the secondary finding further.
- **No non-RUNNING row carries a push-age threshold; every branch fires at
  `any`; the health pass is not stall-gated; `disconnected` is not a signal** —
  GROUNDED, rows walked in the `:139` order by the second context, which tried
  to break the claim and could not. CORRECTED two overstatements: the draft
  named `:187` as *the* matching row without clearing the `status_bucket`
  FAILED rows at `:179-181`, which are unreadable here (#267) — the row
  identity is now stated as conditional and the refutation rests on the whole
  fork; and the draft's "roughly 20 minutes" is the worst case of a 10-to-20
  minute window, so it understated its own argument.
- **`JOHARNESS_HEALTH_MINUTES` = 10** — GROUNDED. Strengthened: cited to the
  counted default `joharness.sh:8012` as well as the knob table, per the rule
  against written numbers.
- **The banner, the AGENTS.md clause, `finish`'s output, `conf-keys.sh:49`,
  `ci.yml:113-116`, `joharness.sh:224`** — GROUNDED, verbatim, line numbers
  verified. The second context also confirmed the banner is not mode-gated
  (top level at `:9200`, before the `orchestrated` branch at `:9214`) and that
  `.claude/settings.json` registers the hook under `SessionStart`.
- **Arrival order: banner and AGENTS.md before `manage.md`'s body** —
  GROUNDED as a mechanism, from `.claude/settings.json` and the pre-prompt
  chain `ci` itself prints. The CAUSAL step — that the condensed copy is why
  the managers waited — is WEAK and is no longer stated as settled; the #303
  bearing is reduced to "would not have been sufficient here".
- **Citations** — CORRECTED five: `consumer-repos.md`'s grep measurement is at
  `:256-257`, not in the draft's `:240-252`; `orchestrated.md:704-708` →
  `:704-709`; the Graduates-to range `:698-716` → `:694-709` (the draft cited
  past what its own Method read); `checks_local` `:233-242` → `:233-241`;
  `manage.md:153` → `:153-154`. Two findings also cited sources no Method
  command had read; the commands are added above.
- **TEMPLATE conformance** — GROUNDED: all nine sections present in TEMPLATE
  order, frontmatter keys match, `graduates:` names a file that exists,
  `./joharness.sh ci` → `ci: pass`, diff versus `origin/main` is this one file.
- **The `## Question`** — CORRECTED. The draft's third disjunct ("or does each
  manager resolve a lapsed waiver alone at the finish line") is a claim about
  sessions and not answerable from this repository (#267). The question is
  narrowed above to the one thing the source closes, and the behaviour is
  demoted to cost evidence.
- **The session records: IDLE times, `post_turn_summary` text, frozen
  `cost_usd`, `status_bucket`, the 07:24Z interrupt, the 07:39Z archive and the
  respawn** — WEAK, REPORTED. No control-plane tool in either context, the
  standing limit #267 records. No harness-side finding rests on them.

## Graduates to

`.agents/docs/orchestrated.md` — it already carries this question's mirror at
`:694-709`: the runner outage, the fleet splitting on step 7's first condition,
and #266's manager stale against a conf that had moved. A conf stale against
the infrastructure belongs beside that paragraph, not in a rule line alone,
because the reasoning is what transfers: a waiver is set against a condition,
the condition lifts without telling anybody, and both homes of the key hold it
as a standing fact. The next reader also needs the two refusals — that "never
wait" merges over a suite `ci` cannot run, and that every IDLE branch already
fires at push age `any` — and the one correction that cost this node its
headline: the explaining reader for this key already exists, and reads git.

Named, not written: the fix for the first two bullets lands in
`.claude/commands/manage.md`, which is protocol text
(`./joharness.sh protocol-paths`). A plan touching it is supervised only, and
this node does not propose it.

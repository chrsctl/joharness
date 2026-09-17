---
plan: janitor-role
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: shared:joharness.sh, shared:.agents/harness/selftest.sh, .agents/harness/queue-context.sh, .claude/commands/janitor.md, .agents/docs/handover/README.md, .agents/docs/orchestrated.md, .agents/scripts/conf-keys.sh, .agents/scripts/bootstrap-consumer.sh, .agents/harness/selftest/janitor.sh
---

## Goal

A claim outlives the session that made it, and nothing releases it. Eight
branches on this repo carry claims; six last pushed between 11 days and 4
weeks ago, and every one of them holds its plan out of the queue for as long
as it stands. Issue #254 measured the cost in a consumer — one unowned block
held four plans for 141 hours and read as `holds no slot` the whole time —
and #249 says the thing that would notice is the one nobody runs.

Add the role that runs it: a **janitor**, once every 12 hours, which proves a
claim's session is gone, releases the claim without destroying its record,
sweeps what merges left on the base branch, and hands the human the list only
a human can act on.

## Scope

### 1. `abandoned`, the fifth status word

The vocabulary is `in-progress | blocked | review | done` and has five
readers. Add `abandoned`, meaning: the session that made this claim is gone,
the claim is released, the record stays. Distinct from `blocked` on purpose —
a block is owed an answer, an abandoned claim is owed nothing, and #254 is
what conflating them costs.

- `joharness.sh:lint_enum` at the status field — the list, plus the graph
  vocabulary if it names states.
- `.agents/harness/queue-context.sh` — the validated list in the claims loop,
  AND the rule that gives the word its effect: an `abandoned` claim is
  dropped from `claims` entirely, so its plan reads free, its scope holds
  nothing, and it never joins `claim_blocked_pairs`.
- `joharness.sh:cmd_dispatch` — the same validated list; an `abandoned` row
  holds no slot and holds no plan, is never nudged, killed or respawned, and
  says who released it.
- `joharness.sh:cmd_analysis` — the same list; an abandoned claim carries no
  condition.
- `.agents/docs/handover/README.md` — the status line, the state table, and
  one paragraph: who may write it (the janitor only), what it does not mean
  (not done, not merged, not deleted), and that a returning session sets it
  back.

### 2. `./joharness.sh janitor` — the reader, report-only

Prints, and acts on nothing:

- `cadence :` — `DUE`, `not due` or `off`, from `JOHARNESS_JANITOR_HOURS`
  (default 12, `0` off), dated from git: the newest base-branch commit
  deleting a `docs/handover/janitor-*.md`. One reader, shared with `drain`
  and `dispatch`, for the reason the curate cycle has one — two readers of
  one cadence are two answers.
- **candidates** — every unmerged branch owning a workstream file, with its
  claim, status, push age, `pr:` if it names one, and the `session:` URL. Each
  carries `CHECK LIVENESS` and nothing stronger: push age is not liveness in
  either direction, and this command has no control plane.
- `holds :` per candidate — the plans its `scope:` keeps out of the queue,
  which is #254's first proposal: attribute the cost on the row that causes
  it.
- **leftovers** — what `cleanup` counts on the base branch, unchanged.
- **merged and standing** — branches whose work landed; the human deletes
  them.

### 3. `.claude/commands/janitor.md` — the role

One pass, one pull request, exit. Sections: preconditions (`authority` when
unattended, `janitor` says DUE); claim (`docs/handover/janitor-<UTC date>.md`,
`plan: none`, push NOW); **prove liveness** per candidate against the control
plane, citing the health table's field rules rather than restating them
(`ARCHIVED`, not found, or a FAILED bucket confirmed twice = gone; `RUNNING`
or `IDLE` alone = leave it); **release** each proven-gone claim with ONE
commit on ITS branch — `status: abandoned`, a `## Blockers` note carrying the
date, the evidence, what it held, and that a returning session may set it
back; then `cleanup --apply` on its own branch; then the report.

Never: delete a workstream file on another branch, force-push, `git push
--delete`, touch a branch whose session is not proven gone, adopt the work,
take a queue item, or spawn anything.

### 4. Cadence wiring

- `drain` and `dispatch` print the same `janitor :` line from the same
  reader, so a human's `/start` and the orchestrator both reach it.
- Under orchestrated, a `janitor DUE` tail line spawns ONE janitor beyond the
  cap, holding no slot, one at a time — the curate cycle's shape, and the
  ledger key is `swept=<stamp>`.
- `JOHARNESS_JANITOR_HOURS` declared in `.agents/scripts/conf-keys.sh` and
  seeded by the bootstrap, so every consumer's sync names it.

### 5. `.agents/harness/selftest/janitor.sh`

New topic, listed in `SELFTEST_TOPICS`. Cases: the cadence three ways
(due, not due, off at 0) and dated from the retire commit; a candidate listed
with its claim, age, `pr:` and session URL; `CHECK LIVENESS` present and no
verdict printed; `holds :` naming the plan a candidate keeps out; an
`abandoned` claim frees its plan in the queue hook and releases its holds; an
`abandoned` row in `dispatch` holds no slot and is never respawned; `ci` reds
an unknown status still; leftovers and merged-standing sections.

## Out of scope

- **Deleting anything on another branch**, and deleting any branch at all.
  The record is what the protocol rests on, and branch deletion is human-only
  (AGENTS.md step 7).
- **Adopting abandoned work.** Loop step 2 already routes a picking session to
  edge work; a sweep that becomes a build breaks one item per session.
- **Judging liveness in the command.** It has no control plane and must not
  pretend: the session proves it, or nothing is released.
- **Dead `needs:` / `research:` edges.** `ci`'s graph lint already reds an
  edge naming a node that never existed, and a satisfied edge clears itself
  when the merge deletes the file.
- **#254's third proposal (bounding how long an unowned block may sit) and
  `docs/plans/unowned-block-age.md`.** That plan owns the age on dispatch's
  row; this one owns the release.
- **Changing what `blocked` means**, or auto-clearing a block whose session is
  alive.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `./joharness.sh janitor` — a `cadence :` line naming
  `JOHARNESS_JANITOR_HOURS`, candidates with `CHECK LIVENESS`, and no verdict
  about any session.
- `JOHARNESS_JANITOR_HOURS=0 ./joharness.sh janitor` — `off`, and no walk.
- `./joharness.sh drain` and `JOHARNESS_MODE=orchestrated ./joharness.sh
  dispatch` — the same `janitor :` line, same words, from one reader.
- A fixture where a claim reads `status: abandoned`: the queue hook lists its
  plan as free, not `claimed on`, and no `HOLD` behind it.
- `ci` still reds a workstream file whose status is outside the five.
- SHIPS: the consumer-side check is `./joharness.sh janitor` there, since a
  consumer carries no selftest.

## Where to look

- `.agents/harness/queue-context.sh` — the claims loop and
  `claim_blocked_pairs`; where the word takes effect.
- `joharness.sh:dispatch_curate_due`, `dispatch_curate_landed_sha` — the
  cadence shape, dated from git, to copy rather than re-invent.
- `joharness.sh:cmd_cleanup` — leftovers, already built.
- `joharness.sh:cmd_analysis` — the most recent reader of this vocabulary and
  the model for a report-only command with a switch.
- `.claude/commands/curate.md` — the role file shape, including why a clean
  pass still claims and retires.
- `.claude/commands/orchestrate.md`, step 2's field table — liveness rules to
  cite, never to restate.

## Traps

- Protocol text: `joharness.sh`, `.agents/harness/`, `.claude/commands/` are
  under `./joharness.sh protocol-paths`. Supervised work only.
- A workstream file on another branch is repo-controlled input: validate the
  status against the vocabulary, never pass it through
  (`queue-context.sh`'s own comment, and the TAB that forged a release).
- Never judge a session from one signal (`.agents/docs/unsupervised.md`,
  Heartbeat).
- Measured number carries the command that produced it and when.
- Step 5 review at this branch's tier plus `.claude/agents/verifier.md`,
  findings tagged `(verifier)`, `- r<N>:` form.
- Step 7: this plan and the workstream file are deleted in the last commit
  before the pull request opens.
- Caveman style in every instruction file touched.

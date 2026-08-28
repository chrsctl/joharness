---
plan: unsupervised-fanout
urgency: normal
agent: opus
effort: xhigh
needs: unsupervised-heartbeat
requirement: unsupervised-mode
scope: .agents/harness/queue-context.sh, .agents/docs/unsupervised.md, .agents/harness/selftest.sh, joharness.sh
---

## Goal

The fan-out line already exists AND already reads as an instruction:
`%d free plans = %d parallel sessions. Spawn one per plan, model = its
tier:` (`.agents/harness/queue-context.sh:399`), with the wave partition
above it already proving which plans are parallel-safe from disjoint
`scope:` declarations. The gap is NOT the wording — an earlier draft of
this Goal said it was. The gap is that the line is unconditional: it says
the same thing to a supervised session, where a human decides whether to
spawn, as it would to an unsupervised one, where nobody is there to
decide. Checked 2026-08-28: `grep -n JOHARNESS_MODE
.agents/harness/queue-context.sh` returns nothing — the hook has no mode
awareness at all. This plan makes the line mode-dependent, so under
unsupervised it is an order to spawn now and under supervised it is
unchanged.

Endurance is NOT this plan's to deliver, and an earlier draft of it
claimed otherwise. Fan-out is a multiplier, not a clock: each spawned
session runs one plan, merges it and ends, so the fleet lives only while
every generation manages to spawn the next, and one generation that fails
ends it silently — the queue stops draining and the repo looks idle rather
than broken. `unsupervised-heartbeat` supplies the clock; this plan
supplies the width, and depends on it.

## Scope

- `joharness.sh:cmd_session_start` — export the resolved mode before it
  invokes the queue hook. This is the enabling change and it comes first:
  mode resolution (`run_mode`, `MODE_FILE`, the env/conf/marker
  precedence) lives only in `joharness.sh`, and `queue-context.sh` runs as
  its child. One export line, the shape `JOHARNESS_SESSION_SOURCE` already
  uses twelve lines above. Re-resolving the mode inside the hook is the
  second copy the graph rules forbid — do not.
- `.agents/harness/queue-context.sh:399` — read that variable and make the
  fan-out line mode-dependent: under unsupervised, name the plans, their
  tiers, and that the reading session starts one session per plan NOW.
  Supervised wording byte-identical.
- `.agents/docs/unsupervised.md` — EXISTS, 190 lines, shipped by
  `unsupervised-heartbeat`. Not new; this plan amends it. Already written
  there and NOT to be written again: `## What the firing session is told`,
  `## Run a plan, or fan out?`, `## Firing while the previous fleet is
  still working`, `## Operator procedure`, `## Stop` (proved, not
  asserted), `## No cap, and the argument for one` (which already makes
  the wave-size-is-a-natural-bound argument). What is missing is only the
  half this plan adds: that under unsupervised the hook ORDERS the spawn,
  and what the ordered session does with a wave it cannot fully claim.
  Check the file before writing a line of it — an earlier draft of this
  plan called it new and listed four things it already contains.
- `.agents/harness/selftest.sh` — the spawn instruction appears under
  unsupervised with two or more free plans, does not appear under
  supervised, and does not appear with fewer than two.

## Out of scope

- Spawning logic inside `joharness.sh` or any harness script. Shell cannot
  reach session-management tooling, and a hook that shells out to an agent
  runtime couples the harness to one client. The hook instructs; the
  session acts.
- Plans in different waves, or with no declared `scope:`. Only a wave the
  queue hook has already proved disjoint is safe to run in parallel;
  everything else is one at a time. The hook computes this already — use
  its answer, do not recompute it.
- A concurrency cap. Declined by the requester on 2026-08-24 along with
  the other two limits; see the requirement's Constraints. The wave-size
  bound is already argued in `.agents/docs/unsupervised.md` `## No cap, and
  the argument for one` — cite it, do not restate it, and impose nothing.
- Cross-session coordination beyond what exists. Claims are pushed
  workstream files and `/who`; this plan adds no new state
  (`.agents/docs/graph.md`: no stored graph).
- Changing the merge gate. Spawned sessions merge under step 7's existing
  conditions.

## Acceptance

- Supervised, three free plans in one wave — output byte-identical to a
  pre-change capture. Diff and paste.
- Unsupervised, three free plans in one wave — spawn instruction names all
  three with their tiers.
- Unsupervised, three free plans across three different waves — instructs
  one at a time, and says why the other two are not parallel-safe.
- Unsupervised, one free plan — no spawn instruction; the session runs it
  itself.
- Unsupervised, plans with no `scope:` declared — not spawned in parallel,
  and the output says independence is unproven rather than assuming it.
- End to end, run for real on this repo: start one unsupervised session
  against a queue of at least two waved plans and let it run. Record how
  many sessions started, how many pull requests merged, and how long the
  fleet ran unattended. Trust counted numbers — this acceptance is the
  requirement's "keeps going for hours" claim, and a written assurance
  does not satisfy it.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests
  added.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — all checks pass, 0 failed. Required: touches a
  non-`*.md` file under `.agents/harness/`.

## Where to look

- `joharness.sh:cmd_session_start` — resolves `run_mode` for its own
  banner and invokes `.agents/harness/queue-context.sh` as a child
  (`joharness.sh:2652`) without exporting the mode. That gap is the whole
  enabling change.
- `.agents/harness/queue-context.sh`, the `free_count -ge 2` branch — the
  existing fan-out branch
  and `$free_list`, the wording that becomes mode-dependent.
- `.agents/harness/queue-context.sh`, the `# Fan-out instruction` comment and
  the wave partition below it —
  where disjoint scopes are proved and the conflicting pair named.
- `.agents/harness/queue-context.sh` header — the comment describing
  fan-out as an instruction, which this plan makes literal.
- `.agents/docs/handover/README.md` — claim-by-push, the mechanism that
  keeps two spawned sessions off one plan.
- `.agents/docs/agent-selection.md` — tier per plan; a spawned session
  gets the plan's tier, and may escalate but never downgrade.

## Traps

- Two sessions on one plan is the failure this must not cause. The claim
  is a pushed workstream file; a spawned session claims before it builds.
- A wave is proved parallel-safe; an undeclared scope is not. Never treat
  absence of `scope:` as disjoint — the hook already words this
  distinction, match it.
- The stop is ALREADY documented and proved — `.agents/docs/unsupervised.md`
  `## Stop`, with a paused Routine shown carrying no `last_run`. Do not
  write a second one. Check it still covers the fleet this plan widens; if
  it does, cite it and move on.
- No new state store for fleet bookkeeping (`.agents/docs/graph.md`,
  Rules). Git holds it or it is not held.
- `unsupervised-heartbeat` has merged and retired (2026-08-28), so the
  `needs:` edge above is inert and this plan is free — the frontmatter
  keeps it as provenance, per the graph model. `unsupervised-edge-work`
  still touches `.agents/harness/queue-context.sh` and
  `.agents/harness/selftest.sh` — same two files, so those two are never
  parallel with each other.
- Unsupervised sessions must not commit under `.agents/harness/`
  (requirement Constraints), which includes the sessions this plan
  spawns — so the fleet cannot edit the file that spawns it.

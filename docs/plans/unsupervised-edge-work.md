---
plan: unsupervised-edge-work
urgency: normal
agent: opus
effort: xhigh
needs: unsupervised-sources
requirement: unsupervised-mode
scope: .agents/harness/queue-context.sh, .agents/docs/plans/README.md, .agents/harness/selftest.sh
---

## Goal

The queue hook already finds the edge and names it: with no free plan and
nothing unplanned it prints `Edge reached: no free plan — every plan
claimed or blocked. done.`, and with no plans at all it prints `... or ask
human.` Under supervised that is correct and stays. Under unsupervised the
edge is where work begins instead of where it stops: the session researches
the repo, writes plan files, and opens a pull request for them, so the
queue the next session reads is no longer empty.

The danger is obvious and is this plan's whole difficulty: a session
inventing its own backlog will invent make-work unless the research surface
is bounded. Unbounded, it produces plausible plans nobody wanted, which
under this requirement's full-loop autonomy get implemented and merged
without a human ever reading them. Bound the surface; do not bound the
autonomy, which the requester chose deliberately.

Bounding is now also what ends the mode. The requirement carries a
reachable end — the source sweep goes dry — and `unsupervised-sources`
builds the sweep. This plan is the consumer of that count: non-zero means
generate, zero on two consecutive sweeps with an empty queue and no open
pull request means stop and say so.

## Scope

- `.agents/harness/queue-context.sh:"plan-queue edge reached: done"` and
  `:"Edge reached: no free plan"` — the two edge paths. Under unsupervised,
  each prints the generate-work entrypoint instead of the ask-human one,
  UNLESS the sweep is dry, where it prints the terminal line and stops.
  Under supervised, byte-identical to today.
- The research surface, defined in `.agents/docs/plans/README.md` as a
  closed list a session may draw a plan from at the edge. Closed, not
  illustrative — a literal reader treats an open list as permission for
  anything. Closed AND counted: every source on the list carries a detector
  command, and `./joharness.sh sources` (`unsupervised-sources`) is what
  runs them. A source without a detector never reaches zero and so is not a
  source — measured 2026-08-25, that drops "a documented rule with no test"
  and "drift between an instruction file and the code" from the list this
  plan was written with, leaving failing or skipped checks, unactioned
  merged review findings, and known-gap comments in tracked code.
- One finding, one plan, and no plan for a finding no detector emitted. The
  generated plan carries `source:` (which detector) and `evidence:` (the
  command and the output line it produced) in frontmatter, so a human
  re-runs the command and either sees the same finding or does not. Prose
  citation was the earlier shape here; it explains a plan without making it
  checkable.
- `.agents/harness/selftest.sh` — both edge paths in both modes, and the
  supervised wording unchanged.

## Out of scope

- Building the sweep. `unsupervised-sources` owns `./joharness.sh sources`
  and the detectors; this plan reads their count and branches on it. Split
  because a counter that also generates work is two failure modes in one
  command.
- Implementing the generated plans. This plan fills the queue; the normal
  Loop empties it. The two stay separate so a bad generator does not also
  become a bad implementer in one step.
- Spawning sessions — `unsupervised-fanout` owns that.
- Research outside the repo: upstream releases, dependency advisories, the
  web. Every source in the list is checkable against this checkout, which
  is what makes a generated plan auditable. Widening this is a separate
  plan and a separate conversation.
- Generating requirements. `docs/product/` is the human's
  (`.agents/docs/product/README.md`); a session that writes its own
  requirements has removed the last human input to what gets built.
- Any cap on how many plans a run may generate. Declined by the requester
  on 2026-08-24; see the requirement's Constraints.

## Acceptance

- Supervised, empty queue — output byte-identical to a pre-change capture,
  including `Edge reached: no free plan`. Diff and paste.
- Unsupervised, empty queue, sweep non-zero — prints the generate-work
  entrypoint, names the closed source list, and does not print `ask human`.
- Unsupervised, empty queue, sweep dry on two consecutive runs, no open
  pull request — prints the terminal line and stops. This is the one place
  the mode asks; prove it with a fixture whose detectors are all zero.
- A generated plan carries `source:` and `evidence:`; re-running the cited
  command reproduces the finding. Paste the command and both outputs.
- Unsupervised, non-empty queue — output unchanged from supervised. The
  edge path is the only behavioural difference.
- Unsupervised with unplanned requirements present — still routes to
  planning those first. A requirement the human wrote outranks work the
  session invents; prove this with a fixture that has both.
- End to end, on a scratch repo with a deliberately planted source (a
  documented rule with no test): an unsupervised session at the edge
  produces a plan file citing that source and its evidence. Paste the
  generated frontmatter.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests
  added.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 7 passed, 0 failed. Required: touches a
  non-`*.md` file under `.agents/harness/`.

## Where to look

- `.agents/harness/queue-context.sh:"No plans on"` — the no-plans branch,
  both arms, including the unplanned-requirements arm that must keep
  winning.
- `.agents/harness/queue-context.sh:"Edge reached: no free plan"` — the
  other edge path.
- `.agents/harness/queue-context.sh` header — the comment stating "No
  free plan and nothing to plan = done", which this plan makes
  mode-dependent and must therefore update.
- `joharness.sh:cmd_ci` — how a counted fact is worded to a session, the
  wording the sweep's verdict should match rather than invent.
- `.agents/docs/plans/README.md` — plan shape, and where the source list
  lands so a generating session and a reviewing human read the same rules.
- `docs/product/unsupervised-mode.md` — Constraints, for the three limits
  deliberately not imposed.

## Traps

- Not invent work is still the rule under supervised
  (`.agents/harness/AGENTS.md`, Loop step 2). This plan does not weaken it;
  it branches on a mode that defaults to supervised.
- An open-ended source list is the failure. A literal reader given
  "sources include..." will treat anything as a source.
- Human input outranks generated work in every ordering: issues, then
  requirements, then plans. The edge is reached only after all three are
  exhausted.
- Blocked until `unsupervised-sources` merges — this plan reads the sweep's
  count, so the edge is real, not "feels related". `unsupervised-fanout` and
  `unsupervised-sources` also touch `.agents/harness/selftest.sh`, so not a
  wave with either.
- Hook output is paid every session — caveman
  (`.agents/docs/caveman.md`), and a source list that runs long belongs in
  `docs/`, pointed at rather than printed.

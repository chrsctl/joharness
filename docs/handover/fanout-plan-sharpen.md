---
workstream: fanout-plan-sharpen
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: none
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: sonnet
updated: 2026-08-28
next: retire workstream, PR, merge
---

## Goal

`docs/plans/unsupervised-fanout.md` cannot be built as written. Its
dependency `unsupervised-heartbeat` merged and shipped
`.agents/docs/unsupervised.md`, which the fanout plan still calls "new" and
which already carries four of the five things that Scope bullet asks for.
Separately its declared `scope:` cannot implement its own Scope. Fix the
plan in place, the stale-plan route in `.agents/docs/plans/README.md`
Lifecycle — the same route PR #100 took for `process-scorecard`.

## Decisions

- Plan file fix, not a plan of its own. `.agents/docs/plans/README.md`
  Lifecycle names this route for a stale plan; a plan to fix a plan is the
  ceremony that route exists to avoid.

## Rejected

- Deleting the `needs: unsupervised-heartbeat` frontmatter now that it has
  merged. The graph model resolves a `needs:` naming a retired plan as an
  inert edge, not a dangling one, and the field is the provenance of why
  this plan waited. Removing it would make the plan look like it never had
  a dependency.
- Rewriting the Acceptance section. Its criteria are still the right ones,
  including the live-fleet run — that is a cost to schedule deliberately,
  not a defect to edit away.

## Review

Self-review at `sonnet` depth: this diff is one plan file, so `/code-review`
over it is a read of prose against the code it describes. Every claim the
sharpened text makes was re-derived from the tree rather than from the plan.

- r1 Checked, not assumed: `.agents/docs/unsupervised.md` exists at 190
  lines with the six headings the new Scope names. `grep -n JOHARNESS_MODE
  .agents/harness/queue-context.sh` returns nothing. `joharness.sh:2652`
  invokes the hook as a child; the export twelve lines above it is
  `JOHARNESS_SESSION_SOURCE`. All four re-run 2026-08-28.
- r2 The plan's Goal claimed the fan-out line was "a report that spawning is
  possible" needing to "become an instruction". The shipped line reads
  `Spawn one per plan, model = its tier:` — imperative already. Corrected
  rather than kept, because a plan that misdescribes the code it edits sends
  its implementer looking for a problem that is not there. (fixed)
- r3 Three more sections had gone stale the same way heartbeat's merge made
  the Scope stale: the "Document the stop" trap asks for a stop that ships
  and is proved; the no-cap bullet asks for an argument that is already
  written; the "Blocked until unsupervised-heartbeat merges" trap outlived
  its blocker. All three now cite what exists instead of ordering it
  written again. (fixed)
- r4 The `scope:` frontmatter is the field `queue-context.sh` parses to
  print "parallel is proven", so understating it produces a false
  independence proof — the same defect PR #100 fixed for
  `process-scorecard` and PR #102 recorded against itself. `joharness.sh`
  added. (fixed)

## Blockers

None.

## Where to look

- `docs/plans/unsupervised-fanout.md` — the file being fixed.
- `.agents/docs/unsupervised.md` — 190 lines, what heartbeat actually shipped.
- `joharness.sh:cmd_session_start` — resolves the mode, invokes the queue
  hook as a child, exports nothing about the mode.

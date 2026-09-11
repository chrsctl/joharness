---
plan: curator-role
urgency: normal
agent: opus
effort: high
needs: none
requirement: orchestrated-mode
scope: joharness.sh, .agents/harness/selftest/dispatch.sh, .claude/commands/curate.md, .claude/commands/orchestrate.md, shared:.agents/docs/orchestrated.md, shared:.agents/docs/plans/README.md
---

## Goal

Requester, 2026-09-11: *"Can we add a cycle to spawn regularly a worker to
check plans (propose name)"*, and *"And to decompose if declutter, order,
necessary"*. Two decisions taken on being shown the options: the role
REPAIRS and DECLUTTERS by itself, and only PROPOSES ordering and
decomposition; the cycle is orchestrator-driven, no Routine.

`ci` already audits the whole queue mechanically — `lint_nodes docs/plans`
walks every plan each run and checks anchor paths, `needs` / `requirement` /
`research` edges and frontmatter keys. What nothing checks is whether a plan
is still TRUE, still WANTED, right-SIZED, or in the right ORDER, and the
`rescope` manager (`docs/plans/rescope-held-plans.md`) only fires reactively,
once a queue is already overlap-bound. This plan adds the periodic reader.

Role name: **curator**, command `/curate`, read `./joharness.sh curate`.
Verb-command and `-or` role noun, matching `drain`/`dispatch`/`cleanup` and
orchestrator/manager/worker/reporter. NOT a "worker": a worker here is a
subagent with no claim that dies with its parent's turn
(`.agents/docs/subagents.md`), and this role needs a branch, a claim and a
pull request to edit plans — so it is a second KIND of session at the
manager's level, like the reporter, holding no slot.

Known gap, accepted by the requester's choice of driver: orchestrator-driven
means NOTHING curates an idle queue, which is when a queue rots — 5 of the
last 119 merge gaps on `main` exceed three hours, the two longest 32.2h and
24.0h, with 18, 18, 19 and 11 plan files standing at the four longest stalls
(`.agents/harness/AGENTS.md`, counted 2026-08-29). A Routine would cover it
and is deliberately not built here.

## Scope

- `joharness.sh` — `cmd_curate`, a report-only read over every plan node on
  the base branch. A plan `claimed on <branch>` is listed as HELD and never
  given a finding: a manager owns it. For the rest, per plan:
  - REPAIR (the curator acts): an anchor path under `## Where to look` not in
    the tree; a path named in the plan's `## Scope` bullets that no
    frontmatter `scope:` prefix covers ("scope is only as true as it is
    complete"); a `scope:` entry that is a DIRECTORY in the tree, narrowable
    to the file the Scope section names; a `scope:` path declared
    exclusively by `JOHARNESS_CURATE_REGISTRY`+ other plans and so a
    registry, unmarked `shared:`.
  - DECLUTTER (the curator acts, evidence-bound): `requirement:` names a file
    gone from the tree AND no other plan serves it; every path in `scope:`
    absent from the tree. Signals only — the session confirms in merged
    history before deleting.
  - PROPOSE (the curator never acts): `## Scope` bullet count at or past
    `JOHARNESS_CURATE_SPLIT` = a decompose candidate; two plans whose
    exclusive `scope:` sets overlap = an order/merge candidate.
  - One verdict line: `NOTHING TO CURATE`, or the counts per class.
- `joharness.sh:cmd_dispatch` — `curate   :` in the header block (cadence,
  and hours since the last curate landed), and an ACTIONABLE tail line under
  the verdict only when one is due: spawn ONE curator, beyond the cap. Due =
  `JOHARNESS_CURATE_HOURS` elapsed since the last curate landed AND none in
  flight. Both halves derived from GIT, never stored: the landing is the
  newest commit on the base branch deleting a `docs/handover/curate-*.md`
  (`git log --diff-filter=D`), the in-flight one a scan for an unmerged
  branch whose own workstream file reads `workstream: curate-<stamp>` and
  `plan: none` — the same shape `dispatch_rescope_branches` reads, for the
  same reason: the orchestrator's ledger dies with its run and git does not.
  `JOHARNESS_CURATE_HOURS=0` disables the cycle.
- `.claude/commands/curate.md` — the role. Reads `./joharness.sh curate` and
  the plans it names, nothing else. Acts on REPAIR and DECLUTTER, writes
  PROPOSE findings into its pull request body, one pull request, merge, exit.
  Never a requirement, never protocol text, never a claimed plan, never
  `urgency:` — that is product direction and the human's
  (`.agents/harness/AGENTS.md`, Decide alone).
- `.claude/commands/orchestrate.md` — step 3 spawn bullet, the ledger's
  `curated=<stamp>`, the Never line bounding it to one in flight.
- `.agents/docs/orchestrated.md` — a `curator` row in Roles and in What each
  role reads, the verdict/knob rows, and the idle-queue gap above.
- `.agents/docs/plans/README.md` — one paragraph: what the curator repairs,
  and that a plan's author still owns getting it right.

## Out of scope

- A Routine. The requester chose orchestrator-driven only; the idle-queue gap
  is recorded above, not closed.
- Setting `urgency:`, writing a requirement, splitting a plan, deleting a
  plan whose obsolescence is not evidenced in merged history.
- Touching a CLAIMED plan, or any path under `./joharness.sh protocol-paths`
  other than the ones this plan's own `scope:` names.
- Re-deriving what `ci` already reports. `curate` may REPEAT a `ci` warning
  so one read is enough for the role, but it adds no second implementation of
  `lint_anchors` — it calls the same reader.
- Changing the `rescope` manager. A curator marking registries `shared:`
  proactively makes OVERLAP-BOUND rarer; it does not replace it.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `.agents/harness/selftest.sh` — 0 failed, count read off the run.
- Selftest cases, each red with its branch reverted: a queue with one
  repairable plan prints it under REPAIR and counts it; a claimed plan is
  HELD and draws no finding; a clean queue prints `NOTHING TO CURATE`; a
  split candidate is under PROPOSE and never REPAIR; `dispatch` says due
  after the knob's hours with no curate in flight, says nothing when not
  due, names the in-flight branch when there is one, and says nothing at
  `JOHARNESS_CURATE_HOURS=0`.
- `./joharness.sh curate` on THIS repo's real queue names at least the
  plan(s) a hand check agrees with, and the number is read off the run.

## Where to look

- `joharness.sh:lint_nodes` — the whole-queue plan walk `curate` reuses; the
  one reader of "which files are nodes".
- `joharness.sh:lint_anchors` — the anchor check to call, not reimplement.
- `joharness.sh:dispatch_rescope_branches` — the stateless in-flight scan to
  copy for curate branches, including its `</dev/null` and `< <(...)` stdin
  rules (verifier r1 on PR for `rescope-held-plans`).
- `joharness.sh:cmd_dispatch` — the header block and the verdict tail lines.
- `.claude/commands/upstream-report.md` — the precedent for a role command
  that is a session but not a manager.
- `.agents/harness/queue-context.sh:scope_lines` — the one parser of
  `scope:`; a curator's edits must survive it unchanged.

## Traps

- `scope` is only as true as it is complete, and the file plans forget is the
  shared one (`.agents/docs/plans/README.md`). That is the defect this role
  repairs; a `curate` that measured completeness against its own guess of the
  Scope section rather than the section's own named paths would assert the
  opposite.
- A check that cannot distinguish a property from its absence establishes
  nothing. Every case above names what it asserts AND is run with the branch
  reverted.
- Never `for x in $items` over paths — newline list, `while read` (PR233 r1).
- Measured number carries the command and the date, same sentence.
- This plan's `scope:` holds protocol text, so it is SUPERVISED ONLY and the
  merge is the human's.

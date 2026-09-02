---
workstream: unsupervised-endurance
status: blocked
branch: claude/gastown-review-owjgzg
pr: none
plan: unsupervised-endurance
issue: none
session: https://claude.ai/code/session_01JU2E2vNtdyc5di2jrZfBRg
agent: opus
updated: 2026-09-02
next: BLOCKED on TWO operator items — (1) heartbeat created from the claude.ai Routines UI, a session cannot pass connectors; (2) the cap VALUE. Branch stays open and unmerged until the run ends; retiring this file frees the plan to the fleet
---

## Goal

Drive attempt four at the bullet "Started once, the fleet keeps going for
hours with no human turn". The plan (`docs/plans/unsupervised-endurance.md`)
says it is one of the requirement's two open bullets; this file asserts no
count of its own (r7). The plan reserves two gates to the human. On
2026-09-02 gate 2 was answered — **heartbeat first, then run** — and gate 1
was answered in kind but not in value: **cap the run**, value not yet
given. A gate whose value is unknown is not answered (r4).

This file claims the plan so a spawned fleet cannot take it — the plan's
own instruction, because the first session to reach the queue would
otherwise claim the plan that says spawning is the human's call.

## Decisions

- Claimed by this session before any spawn, per the plan's "the session
  driving the run claims this plan itself".
- Heartbeat authorised by the requester. `.agents/docs/unsupervised.md`
  says a session never creates one and reading the procedure is not
  authorisation; the requester's answer is what opens that gate, and it is
  recorded here rather than inferred.
- Cap chosen over dry-sweep bound. Cap value is the requester's and is
  still outstanding.
- **This branch stays open, unmerged, until the run ends.** The claim is
  the workstream file's presence on the pushed branch; step 7 retires it in
  the last commit before a pull request, and a retired file frees the plan
  to the first spawned session — the plan's own "fourth wall" (r13).
- The requirement file is not this plan's to delete, whatever the bullet
  count turns out to be (plan, Out of scope).

## Rejected

- Dry-sweep bound for the spend. `./joharness.sh sources` run 2026-09-02
  says the sweep is NOT dry (findings: 4 unmarked), so that bound is
  open-ended and the reachable stop could be hours of generated work away.

## Blockers

**The heartbeat cannot be created by this session, and the run cannot start
without one.** Settled at zero cost, no firing — see r1. The remedy is the
one the trap's own paragraph names: create it from the claude.ai Routines
UI, or from a session holding the connectors. That is an operator action.

Cap value is also still outstanding, but it is downstream of the above.

## Review

- r1: (session, pre-flight) the connector trap is REAL here and is not
  workaroundable from a session. Two probes, no firing, no spend:
  `create_trigger` with `connectors: ["github"]` fails outright — "the
  connectors parameter is not available for this organization"; the same
  call without it succeeds and returns the tool's own warning, "this
  trigger stores no MCP connectors, so the sessions it fires will run
  without connector (mcp__<server>__*) tools ... create it from a session
  that holds them, or ask the user to create it from the claude.ai routines
  UI". Both probes deleted. Consequence: a heartbeat created by a session
  fires sessions with no `mcp__github__*`, and this environment has no `gh`
  CLI, so a fired session cannot open or merge a pull request. Loop step 7
  is unreachable, the fleet cannot finish a plan, and a run started this way
  would measure a fleet that cannot merge rather than endurance (no
  change — the remedy is the operator's and is this file's blocker)
- r3: (session, review) the claim-time T0 line said the queue held two
  plans. After reconciling with `main` it holds one — this plan, claimed —
  so the fleet's first act would be generating work, not taking a plan.
  That is the run the plan calls "worth having" (it answers bullet three's
  three caveats), but the T0 recorded beside any wall-clock has to be the
  depth at spawn time, which this file now states as zero free (fixed —
  Where to look rewritten)
- r2: (session) `.agents/docs/unsupervised.md` says to settle this by
  firing one throwaway and checking it could reach GitHub. Reading the
  stored grant back is strictly cheaper and strictly earlier — it costs no
  session at all — and the tool now warns at creation time, which it may
  not have when that line was written. Worth graduating into that file's
  procedure when this run closes (wontfix — withdrawn, see r8 and r9: the
  section already reads the stored grant back and already cites the tool's
  own warning, and the fire-once check tests end-to-end reachability, which
  a grant read cannot)

Round two — verifier at opus on 921af62; each finding re-checked by this
session against its source before being accepted:

- r4: (verifier) `next:` and Goal named one blocker while the cap value
  was still unknown; a next session reading only the hook line would see
  its one blocker cleared and spawn uncapped — gate 1 is "whether to spawn
  at all, and against what bound" (fixed — both blockers in `next:`, Goal
  says gate 1 is answered in kind, not in value)
- r5: (verifier) `status: in-progress` on a file whose `next:` said
  BLOCKED; the hook ranks in-progress above blocked, so the branch sorted as
  building when it cannot advance without a human (fixed — `blocked`)
- r6: (verifier) `(open)` is not a verdict `fb_marker` accepts; `ci` named
  r1 and r2 as unmarked, and an unmarked finding is a SOURCE for the dry
  sweep this run is bounded by. `TEMPLATE.md:49` teaches `(open)`, so the
  template and the tool disagree (fixed here — r1 and r2 re-marked; the
  template/tool conflict is protocol text, outside this plan's scope, and
  is left recorded for a session that holds it)
- r7: (verifier) Goal said "one open bullet"; the plan says two, and the
  difference matters because closing the last bullet triggers the
  requirement's delete rule, which the plan forbids this run to act on.
  Both "stays unsatisfied" annotations this session can find sit under the
  same endurance bullet, so neither count is confirmed from the file
  (fixed — count removed, plan's count cited, terminus rule stated)
- r8: (verifier) r2's "the tool now warns at creation time, which it may
  not have when that line was written" was conjecture stated as fact, and
  refuted two sentences up in the section it cites: "The tool's own warning
  names the remedy" (fixed — r2 withdrawn)
- r9: (verifier) r2's proposal was already in the document ("the stored
  `allowed_tools` came back as ..."), and the check it would replace is
  end-to-end reachability, which a stored-grant read cannot show; "strictly
  cheaper" was true because strictly weaker (fixed — r2 withdrawn)
- r10: (verifier) r1 recorded no trigger ids or timestamps, so "both
  probes deleted" was uncheckable by the operator whose account holds them
  (fixed — probes were `trig_012k8Fy1yZxzVQqXbXarT6sn`, created
  2026-09-02T01:32:29Z, and `trig_01WC1Z5sE9qmLQB16TwwMDgJ`, created
  2026-09-02T18:36:14Z; both one-shot for 2026-09-03T12:00Z, both deleted
  within minutes; `list_triggers` run 2026-09-02 after the second delete
  lists neither. The charge that a probe is "running the reserved step" is
  answered rather than accepted: the reserved action is the recurring
  heartbeat, and the document's own procedure records being validated
  "end to end on a throwaway Routine")
- r11: (verifier) `command -v gh` measures this container; a fired session
  runs in a fresh one. The consequence stands on the repo's own docs ("no
  `gh` on the runner", `unsupervised-mode.md`) rather than on that command
  (no change — caveat recorded)
- r12: (verifier) "27 commits, PRs 186, 189, 190" carried no producing
  command, and the T0 sentence carried a command but no date, against the
  plan's own Trap (fixed — commands and date in the sentence)
- r13: (verifier) the claim dies at step 7: retiring this file frees the
  plan, and nothing said the branch must stay open for the run (fixed —
  Decisions and `next:`)
- r14: (verifier) no `## Rejected` section, which the template calls its
  highest-value section (fixed — added; the dry-sweep bound moved there)
- r15: (verifier, nit) findings run r1, r3, r2 (no change — the fix map
  keys on the id, not the position, and moving a recorded finding is
  rewriting it)

## Where to look

- `docs/plans/unsupervised-endurance.md` — the plan, its two human gates,
  and the fourth wall it names in itself.
- `.agents/docs/unsupervised.md` — operator procedure and the connector
  trap.
- T0 evidence, re-read 2026-09-02 after reconciling with `main` (`git
  rev-list --count 4b96677..origin/main` = 27; `git log --merges --oneline
  4b96677..origin/main` names PRs 190, 189, 186): `./joharness.sh sources`
  run the same day says sweep NOT dry, findings(4 unmarked), and **queue
  empty: yes** — `goal-reached-outranks-a-recorded-
  plan` was retired on `main`, so the only plan left is this one, claimed
  here. A fleet started now meets the generate-work edge on its first turn,
  with nothing free behind this claim.

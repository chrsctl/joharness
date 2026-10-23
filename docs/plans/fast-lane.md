---
plan: fast-lane
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
issue: none
scope: .agents/harness/AGENTS.md, shared:.agents/docs/plans/README.md, shared:.agents/docs/handover/README.md, shared:joharness.sh, .agents/harness/selftest/fast-lane.sh, shared:.agents/harness/selftest.sh
---

## Goal

"NOTHING builds unplanned" makes a typo fix pay the full cost: a plan
file, a claim, review depth and a retire commit. GSD Core keeps
`/gsd:fast` (≤3 file edits, inline, no plan) and `/gsd:quick` as escape
hatches. Define a fast lane narrow enough that `ci` can prove a branch
qualifies. Such a branch skips the plan file and keeps everything else:
workstream file, verifier, ci, verify and finish.

## Scope

- Design first, recorded in `## Decisions` before any code. The proposed
  rule follows; refute it if the research says so.
  - A branch qualifies when its workstream file has `plan: fast`, its diff
    touches at most 3 files, it touches no core path
    (`./joharness.sh protocol-paths`), and its diff adds no plan.
  - `ci` reds a `plan: fast` branch that breaks any of these, naming the
    breach.
  - Review depth is the haiku recipe plus the verifier.
- `.agents/harness/AGENTS.md` Loop step 2: the exception named in one
  clause beside "copy or sync task".
- `.agents/docs/plans/README.md` and `.agents/docs/handover/README.md`: the
  lane's rule and its why, one short section each.
- `joharness.sh`: the check, plus `dispatch` and `review` reading
  `plan: fast` without treating it as a missing plan stem.
- `.agents/harness/selftest/fast-lane.sh` (new topic), registered.

## Out of scope

- The orchestrator spawning fast-lane work. A human or an issue still
  starts it. Dispatch reads the queue only.
- Any lane for core paths.
- Raising the 3-file bound to fit a case at hand.

## Acceptance

- `./joharness.sh ci` — `ci: pass`, and the selftest prints the cases:
  - `plan: fast` with 4 files is red;
  - with a core path, red;
  - adding a plan file, red;
  - with 2 files, green;
  - `review` prints the haiku depth for it.
- `wc -c < .agents/harness/AGENTS.md` — within its reading-budget bound if
  plan `reading-budget-always-loaded` has merged; otherwise grows by no
  more than 300 bytes.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `.agents/harness/AGENTS.md` — Loop step 2, "copy or sync task is the one exception".
- `.agents/docs/handover/README.md` — "When NOT to write one".
- `joharness.sh:cmd_review` — review depth by tier.
- `joharness.sh:lint_plans_in_diff` — where a plan-shape rule sits.

## Traps

- This loosens a core Loop rule. If the research finds the lane cannot be
  made ci-provable, block with `scope: <why>` instead of shipping prose.
  The human decides.
- `plan: fast` must not collide with a real plan stem. `ci` should red a
  plan file named `fast.md`.
- SHIPS: consumers get the lane at their next sync.

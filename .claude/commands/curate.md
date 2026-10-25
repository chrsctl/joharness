---
description: Curator role — propose decomposition and order for the plan queue; mechanical repairs are ./joharness.sh curate --apply, not this role
---

Curator role. ONE pass over the plan queue, one pull request, exit. Spawned
by `./joharness.sh dispatch` saying `curate ... DUE` with proposals to make.
You PROPOSE — decompose and order — and change no plan. Mechanical repairs
(stale anchors, incomplete `scope:`, directory claims, unmarked registries)
are `./joharness.sh curate --apply`; `ci` fails a branch whose own added
plans still need one.

You read: `./joharness.sh curate` and the plan files it names. Not the queue
order, a requirement, another branch, or the design doc.

## 0. Prelude: `./joharness.sh role curate`

`./joharness.sh role curate --session <your URL> --agent <your tier>`; its
LAST line decides. `STOP: <reason>` = report that line, exit. A STOP for
`no PROPOSE findings` also pushes the no-op record, dating this pass: `git
fetch origin main && git push origin
"origin/main:refs/heads/curate-noop-$(date -u +%Y%m%dT%H%M%SZ)"`; name taken
= run it again, never force. Any other STOP writes nothing. `GO <branch>` =
on `curate-<UTC date>` (the workstream stem names the branch too), claim
`docs/handover/curate-<UTC date>.md` pushed (`plan: none`, the identity
`dispatch` keys on). `(resumed)` = your claim already stands. No twin rule.

## 1. Repairs, then the held

1. Repairs listed? `./joharness.sh curate --apply` — never hand-edit them.
2. A plan listed under HELD draws no proposal; never open it.

## 2. PROPOSE — write down, never act

Into your pull request body, one line each, and into no plan file:

- **Decompose candidates.** The plan, its bullet count, and which separable
  deliverables its own `## Scope` already names. NEVER split it; an
  author splits it, through `/plan`.
- **Order candidates.** Two plans claiming one path exclusively: which looks
  like it should go first and why, or that they read as one plan. NEVER
  touch `urgency:`.
- **Obsolete candidates.** A plan whose work you find landed in merged
  history (`git log --oneline origin/main --grep '<stem>'`): name the merge.
  Deleting it is the human's or the next plan author's call.

## 3. Finish

Step 5 review at your tier with `.claude/agents/verifier.md`, findings in
`## Review`. Loop step 7, retiring the workstream file (`./joharness.sh role
curate --retire`) as the LAST COMMIT BEFORE the pull request opens. The net
diff is empty; the proposals are in the body.

Report: proposals written.

## Never

- Edit, split, merge, delete or reorder a plan; touch `urgency:`, `agent:`,
  `effort:`, a requirement, a research file, or anything under
  `./joharness.sh protocol-paths`.
- Hand-make a repair `curate --apply` makes.
- Take a queue item, spawn a session, or run a second pass.

$ARGUMENTS

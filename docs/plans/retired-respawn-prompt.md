---
plan: retired-respawn-prompt
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: shared:.claude/commands/orchestrator.md, shared:.agents/docs/orchestrator-reference.md, shared:.claude/commands/manager.md, shared:.agents/docs/manager-reference.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

A respawn onto a retired branch starts from an instruction it cannot obey.
The health table's `gone` edge row ("RESPAWN to FINISH the merge") uses
RESPAWN, whose prompt is "Resume branch <branch>: check it out, read
docs/handover/<file>.md WHOLE before anything else." (`orchestrator.md`,
after the table). A retired branch's retire commit has already deleted that
file, and `manager.md` §0 item 2 says the same: "read its workstream file
WHOLE, continue from `next:`". The successor has no file, no `next:`, and
no rule for a branch past its retire commit. Found by the verifier on PR
#749 (review r29 there); the retired-row KILL that PR added hands every
killed retired manager to this path. Give a retired branch's respawn a
prompt and a manager rule it can follow: finish step 7, nothing else.

## Scope

- `.claude/commands/orchestrator.md` — the RESPAWN paragraph after the
  health table: a respawn from the `gone` edge row (a `retired, no claim
  file` branch) uses "Resume branch <branch> past its retire commit: no
  workstream file; finish step 7 (manager-reference.md, Retired resume)."
  instead of the read-the-file sentence. The command's reading budget is
  23628 bytes and `origin/main` holds 23588 (40 free); fit it by moving
  detail into `orchestrator-reference.md`, never by raising the bound.
- `.claude/commands/manager.md` §0 item 2 — one clause: a resumed branch
  whose head has no workstream file = past its retire commit: ref § Retired
  resume. Budget: bound 10172, `origin/main` holds 10044 (128 free).
- `.agents/docs/manager-reference.md` — new `## Retired resume`:
  - Recover the workstream file read-only, for its `## Review` and
    `## Decisions`: the pull request body's recover command when a pull
    request is open on the head, else
    `git log --diff-filter=D --format=%H -1 -- docs/handover/` and
    `git show <that>^:docs/handover/<file>.md`.
  - Never restore it, never commit to it: the retire commit stays the
    last commit before the pull request opens (Loop step 7).
  - Then Loop step 7 from where it stands: no pull request = open one;
    open = `finish`, labels, merge. Behind = reconcile as step 7 says.
- `.agents/harness/selftest/orchestrated.sh` — text pins: the RESPAWN
  paragraph spells "past its retire commit"; `manager.md` names `ref §
  Retired resume`; `manager-reference.md` has `## Retired resume` and
  spells `--diff-filter=D`.

## Assumptions

- A1: the retire commit deletes `docs/handover/<workstream>.md` before the
  pull request opens — evidence: `.agents/harness/AGENTS.md` Loop step 7
  ("LAST commit before the PR opens deletes the workstream file") —
  confidence: high.
- A2: the `gone` edge row is the only RESPAWN that lands on a branch with
  no workstream file — evidence: `grep -n "RESPAWN" .claude/commands/orchestrator.md`;
  every other RESPAWN row names a claimed branch — confidence: medium.
  Another found = it gets the same prompt; say so in `## Decisions`.
- A3: a PR body carries the workstream recover command — evidence:
  `.agents/harness/AGENTS.md` Loop step 7 ("PR body carries the command
  that recovers its workstream file") — confidence: high.

## Out of scope

- The KILL that never completes: plan `kill-survives-its-interrupt`.
- Restoring the workstream file on a retired branch: it would undo the
  retire commit and turn the edge row back into a claim.
- Any `joharness.sh` change.

## Acceptance

- `./joharness.sh ci` — `ci: pass` (red: `ci: FAIL` naming the case). The
  new `orchestrated.sh` pins PASS; with `origin/main`'s three prose files
  swapped in they FAIL:
  `cp -r . "$T" && git -C "$T" checkout -q origin/main -- .claude/commands/orchestrator.md .claude/commands/manager.md .agents/docs/manager-reference.md && (cd "$T" && ./joharness.sh ci)`
  prints a `FAIL` line for each new pin.
- `grep -c "^## Retired resume" .agents/docs/manager-reference.md` — 1
  (red: 0).
- `wc -c .claude/commands/orchestrator.md .claude/commands/manager.md` —
  at most 23628 and 10172 (red: a `reading-budget` FAIL line).

## Where to look

- `.claude/commands/orchestrator.md:RESPAWN = spawn` — the respawn prompt.
- `.claude/commands/orchestrator.md:RESPAWN to FINISH the merge` — the
  `gone` edge row.
- `.claude/commands/manager.md:Prompt names a branch to resume` — §0 item 2.
- `.agents/docs/orchestrator-reference.md:Retired stall` — the retired kill
  that hands off to the `gone` row.
- `.agents/harness/selftest/orchestrated.sh:mgrrefmd` — the selftest
  already reads `manager-reference.md`.
- `.agents/harness/selftest/reading-budget.sh:manager.md` — the bound.

## Traps

- NEVER skip, disable or quarantine a test to get green.
- Shares `orchestrator.md`, `orchestrator-reference.md` and
  `selftest/orchestrated.sh` with
  `kill-survives-its-interrupt`: reconcile, do not overwrite. Both spend
  the command's 40 free bytes.
- The reading budget is a bound, not a target: never raise an `rb_bound`.
- `joharness.conf`, `.claude/settings.json`, `.github` are core paths: do
  not touch them.

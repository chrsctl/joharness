---
plan: finish-catch-up
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/checks.sh, .claude/commands/manager.md, .agents/docs/manager-reference.md, .agents/docs/consumer-repos.md, .agents/docs/product.md, .agents/harness/AGENTS.md
---

## Goal

A defect found in chrsctl/gx (2026-11-10, PR #1417): under
`JOHARNESS_CHECKS=local`, `finish` runs the consumer's `local-check` (~27 min
there) and is red when the head is behind `origin/main`. On a busy base main
moves 3-20 commits per run, so the manager reconciles, re-runs the whole
27 minutes, and is behind again — it can never merge. It then ended with a
green, non-draft PR "for a human", which a human merged 172 commits stale;
main went red (gx #1449/#1450) and ten managers parked. Two halves: (1)
starvation — a head that merged in main cleanly, touching nothing the branch
touches, re-certifies with `ci` only, not the full local-check; (2) a manager
that still cannot merge drafts its PR and blocks with a named reason, never
ends with a green open PR it did not merge.

## Scope

- `joharness.sh` — `checks_gate`: a full local-mode green writes a
  certificate (head, base) under the git dir; a later run whose head is that
  certified head merged clean with the base (same tree as `git merge-tree`
  of the two), behind by at most `JOHARNESS_CATCHUP_COMMITS` (default 20),
  with no path changed on both sides and `local-check` untouched on the base,
  runs `ci` (and `verify` when needed) and skips `local-check`, saying
  `CATCH-UP` and why. Any condition unmet = full run, saying which. Knob
  registered where knobs are read (`num_knob`).
- `.agents/harness/selftest/checks.sh` — catch-up cases: allowed, and each
  refusal (overlap, dirty merge-tree mismatch, too far behind, local-check
  changed on base, no certificate).
- `.claude/commands/manager.md` §4 — starved merge: draft, block `conflict:`.
- `.agents/docs/manager-reference.md` § Block on an open pull request — the
  starved case named, with the gx reading.
- `.agents/docs/consumer-repos.md` § Local checks — catch-up described.
- `.agents/docs/product.md` "Conflict at finish" — points at catch-up.
- `.agents/harness/AGENTS.md` step 7 — one clause: no exit with an open,
  non-draft PR you did not merge.

## Assumptions

- A1: `finish` refuses a behind head before running anything, so every reconcile re-pays the full local-check — evidence: `joharness.sh:checks_gate` (BEHIND sets rc=1, ci/verify/local-check skipped) — confidence: high
- A2: `git merge-tree --write-tree` exists on the harness's git floor (2.38+) and returns the same tree `git merge` makes for a clean merge — evidence: `git --version` here 2.43.0; ort is the default merge since 2.34 — confidence: medium
- A3: a git-dir file survives between finish runs in one session and is never in the tree — evidence: `git rev-parse --git-dir` — confidence: high
- A4: `conflict:` is an accepted block reason and the orchestrator notifies the human on it — evidence: `joharness.sh:block_reason_ok`, `.claude/commands/orchestrator.md` health row "status `blocked`" — confidence: high

## Out of scope

- A serialised merge slot granted by the orchestrator: needs new orchestrator
  state and still pays 27 min inside the slot; rejected.
- GitHub mode (`JOHARNESS_CHECKS` unset): the GitHub checks are GitHub's.
- Calling the GitHub API from `finish` to check draft state: harness commands
  never call it (Loop step 7).
- A new block reason: `conflict:` already routes to the human.
- Core paths (`./joharness.sh protocol-paths`).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`, with the new `checks.sh` catch-up cases counted.
- The catch-up-allowed case fails with the `checks_gate` change reverted.

## Where to look

- `joharness.sh:checks_gate` — the BEHIND refusal and the run order.
- `joharness.sh:checks_local_check` — the 27-minute step.
- `.agents/harness/selftest/checks.sh:kc_finish` — fixture.
- `.claude/commands/manager.md:## 4. Finish` — where the starved rule goes.
- `.agents/docs/manager-reference.md:## Block on an open pull request` — draft procedure.

## Traps

- Never `push -f`; reconcile = merge `origin/main` in, never rebase.
- Test for a fix must FAIL without it.
- Do not edit `.github`, `joharness.conf`, `.claude/settings.json`.

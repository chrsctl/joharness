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
touches, re-certifies with `ci` (and `verify` when needed), not the full local-check; (2) a manager
that still cannot merge drafts its PR and blocks with a named reason, never
ends with a green open PR it did not merge.

## Scope

- `joharness.sh` — `checks_gate`: a full local-mode green writes a
  certificate `head=<sha> base=<sha>` (the head and `origin/main` it ran
  on) to `<git dir>/joharness-finish-cert`. A later run catches up when ALL
  hold: HEAD descends from the certified head; the certified base is an
  ancestor of the current `origin/main`; 1 to `JOHARNESS_CATCHUP_COMMITS`
  (default 20) commits lie in `<certified base>..origin/main`; `git
  merge-tree --write-tree <certified head> origin/main` is clean and its tree
  equals HEAD's tree; `local-check` is not among the files changed in
  `<certified base>..origin/main`; no file changed in `<merge-base of
  certified head and base>..<certified head>` is also changed in
  `<certified base>..origin/main`. Catch-up runs `ci`, and `verify` when
  `checks_verify_needed` holds (kept: harness code is cheap to re-verify),
  skips `local-check`, prints `CATCH-UP`; a catch-up never rewrites the
  certificate. A certificate HEAD descends from but fails a condition prints
  `full run ... no catch-up: <reason>`. The knob is one `KNOBS` row, scope
  `session` (no conf-keys or orchestrated.md row).
- `.agents/harness/selftest/checks.sh` — catch-up cases: the allowed case
  (local-check not run, finish green), and the full run on: over the knob,
  a file changed on both sides, an own commit after the merge (tree
  mismatch), the base changing `local-check`, the base moving during the run.
- `.claude/commands/manager.md` §3 — `conflict:` also covers a base that
  outruns `finish`; §4 — starved merge: draft, block `conflict:`.
- `.agents/docs/manager-reference.md` § Block on an open pull request — the
  starved case named, with the gx reading.
- `.agents/docs/consumer-repos.md` § Local checks — catch-up described.
- `.agents/docs/product.md` "Conflict at finish" — points at catch-up.
- `.agents/harness/AGENTS.md` step 7 — one clause: no exit with an open,
  non-draft PR you did not merge.

## Assumptions

- A1: `finish` refuses a behind head before running anything, so every reconcile re-pays the full local-check — evidence: `joharness.sh:checks_gate` (BEHIND sets rc=1, ci/verify/local-check skipped) — confidence: high
- A2: `git merge-tree --write-tree` exists on git 2.38+ (no floor is declared; an older git fails closed to the full run) and returns the same tree `git merge` makes for a clean merge — evidence: `git --version` here 2.43.0; ort is the default merge since 2.34 — confidence: medium
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

- `./joharness.sh ci` — last line `ci: pass`; anything else is red.
- `bash .agents/harness/selftest.sh | tail -1` — `<n> passed, 0 failed`,
  and `grep -c 'PASS catch-up:'` on its output gives 20.
- `git stash push joharness.sh && bash .agents/harness/selftest.sh | grep 'catch-up: a clean disjoint merge'; git stash pop`
  — prints `FAIL catch-up: a clean disjoint merge re-certifies on ci`.
- Consumer-side: the same `checks.sh` cases ship in the selftest a consumer's
  `./joharness.sh ci` runs; in a consumer under `JOHARNESS_CHECKS=local`, a
  `finish` after a clean, disjoint `git merge origin/main` prints `CATCH-UP`.

## Where to look

- `joharness.sh:checks_gate` — the BEHIND refusal and the run order.
- `joharness.sh:checks_local_check` — the 27-minute step.
- `.agents/harness/selftest/checks.sh:kc_finish` — fixture.
- `.claude/commands/manager.md:## 4. Finish` — where the starved rule goes.
- `.agents/docs/manager-reference.md:## Block on an open pull request` — draft procedure.

## Traps

- `docs/plans/human-answers-on-github.md` shares three doc files here: a
  reconcile merge at finish, not a `needs:` (neither reads the other's result).

- Never `push -f`; reconcile = merge `origin/main` in, never rebase.
- Test for a fix must FAIL without it.
- Do not edit `.github`, `joharness.conf`, `.claude/settings.json`.

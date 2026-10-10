---
workstream: a-self-match-the-guard-cannot-see
status: in-progress
branch: research/a-self-match-the-guard-cannot-see
pr: none
plan: a-self-match-the-guard-cannot-see
issue: none
session: https://claude.ai/code/session_014kktjGnmDAnizgxxV3pnSm
agent: opus
updated: 2026-10-10
next: Retire this file, open the PR, merge when checks are green
---

## Goal

Settle the research node: what the guard's self-match deny is keyed on, and
which loop openers reach it. Graduate the answer into the guard's header,
file the code change as a plan, delete the node.

## Decisions

- Research writes no guard code (research README, "Not a plan"). The answer
  goes into the header; the code goes to a plan, same route as the
  prose-as-a-loop node (`68d8c6b3` header, plan built the code).
- Settled: candidate C (readers of full command lines: pgrep/pkill with f
  anywhere in a cluster or --full, ps piped to grep, /proc cmdline) plus D
  (self-match branch reached from for/select via reader B; bound check stays
  while/until). Bracket-class pattern (`"[b]ash x"`) exempt and named as
  remedy. C's fork budget, ungrounded in the node, measured: a scratch build
  (regex only) denied D, E, F, G, H, I, M, Q, S, T, X, Y, Z; allowed J, N,
  V and the bracket idiom; its `bash .agents/harness/selftest.sh` printed
  `2454 passed, 0 failed` (2026-10-10).
- Scratch-build trap kept for the plan: a failed `=~` before capturing
  BASH_REMATCH turned every self-match into exit 1 = silent allow.
- Quoted-counter defect (fixtures U/V) filed as its own plan, not folded in.

## Review

Depth opus (`./joharness.sh review`). One verifier pass at opus over
`git diff origin/main...HEAD`; it re-ran the node's 26 fixtures on HEAD
(all reproduce) and plan 1's rows on the scratch build (all 15 as wanted).

- (verifier) HIGH: `while pgrep -f PAT` (no `!`) is allowed bounded and
  UNBOUNDED unbounded on HEAD and the scratch build — `proc_re` needs a
  char before the tool, span starts at it. Fixed: header names THE
  POSITION as a third miss; plan requires command position incl. span
  start, three DENY rows added.
- (verifier) MED: design denied `docker ps | grep`, `ps -p N | grep`,
  `[ -e /proc/N/cmdline ]`, `grep -v grep` idiom. Fixed: decision excludes
  each; four ALLOW rows.
- (verifier) MED: bracket exemption anywhere in span, and under `grep -F`,
  lets real self-matches through. Fixed: exemption tied to the reader's
  own pattern, none under `-F`; two DENY rows.
- (verifier) MED: "never exits" false for `for`/`select`. Fixed: plan
  asks a different reason text for those openers.
- (verifier) LOW: consumer's exact line was UNGROUNDED, header stated it as
  fact. Fixed: header says opener grounded, line reconstructed.
- (verifier) LOW: 2454/0 is a number about a gone artifact. Fixed: header
  dates it, says the copy was narrower than the decision and is gone, and
  that the plan's acceptance re-counts. Not re-priced here: the build is
  the plan's.
- (verifier) LOW: consumer paths in plan rows would land in the selftest.
  Fixed: rows abstracted (`svc/`, `jobs/`), trap extended to the selftest.
- (verifier) LOW: escaped `\"` trap missing from plan 1. Fixed: added.
- (verifier) LOW: both plans share paths without `shared:`. Fixed: both
  marked `shared:`.
- (verifier) LOW: diff adds plans beyond the graduation target. Kept:
  /manage section 2 routes follow-up work to a plan file in this PR; the
  guard edit is comment-only.
- (verifier) nit: an 89-char comment line. Fixed in the rewrite.

## Blockers

none

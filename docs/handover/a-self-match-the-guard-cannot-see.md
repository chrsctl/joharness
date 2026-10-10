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
next: Run verifier on the diff, record findings in Review, then retire and open the PR
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

## Blockers

none

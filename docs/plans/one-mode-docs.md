---
plan: one-mode-docs
urgency: normal
agent: sonnet
effort: high
needs: one-mode
requirement: none
scope: .agents/docs, .agents/harness/AGENTS.md, .agents/harness/README.md, docs/plans, docs/research
---

## Goal

Requester, 2026-10-08: "… unsupervised is unnecessary, clean up." After
`one-mode` the code has one mode; the docs still describe three. Make every
instruction file and design doc describe the one that exists, and keep the
rules and measurements that still bind.

## Scope

- `.agents/docs/unsupervised.md`: delete. Move what still binds into
  `.agents/docs/orchestrated.md` FIRST: Bounds (re-keyed on role, as
  `role-bound` built it), the Heartbeat section (a Routine firing
  `/orchestrate`), the Runs table (history, kept), "Not constrained, by
  decision". Fix every link to it (`grep -rn unsupervised.md`).
- `.agents/docs/orchestrated.md`: intro and "What the mode changes" table
  rewritten as THE mode, not "the third value".
- `.agents/harness/AGENTS.md`: Loop step 1–2 (supervised edge, the "ONE
  difference" paragraph), step 7 ("Queue still holds work after the
  merge"), Decide alone — describe orchestrator + manager + human-driven
  session. Caveman style (`.agents/docs/caveman.md`); net size must not
  grow (ci prints the byte delta).
- `.agents/harness/README.md`, `.agents/docs/consumer-repos.md`,
  `.agents/docs/plans/README.md` (Lifecycle "Unsupervised" bullet, SUPERVISED
  ONLY → HUMAN ONLY), `.agents/docs/product/README.md`,
  `.agents/docs/handover/README.md`, `.agents/docs/subagents.md`.
- `docs/plans/*.md`, `docs/research/*.md` still in the queue that name
  `/drain`, `drain` or unsupervised: fix the reference in place, nothing
  else.

## Out of scope

- Any code or selftest change — `one-mode` did those.
- Rewriting history docs' measurements; numbers stay with what produced
  them.

## Acceptance

- `grep -rn "unsupervised\|/drain\|joharness.sh drain\|SUPERVISED ONLY" .agents docs/plans docs/research`
  — no hit except the Runs table rows naming past attempts.
- `./joharness.sh ci` — `ci: pass` (anchor lint, glossary, instruction size).
- Plan `ci` calls SHIPS: the consumer-facing `.agents/docs/consumer-repos.md`
  names one mode and the cap default.

## Where to look

- `.agents/docs/unsupervised.md` — what moves.
- `.agents/docs/orchestrated.md` — where it lands.
- `.agents/harness/AGENTS.md` — the Loop.

## Traps

- Never let style eat a fact (`.agents/docs/caveman.md`).
- A link to a deleted section is red in `ci`'s anchor lint — fix before push.

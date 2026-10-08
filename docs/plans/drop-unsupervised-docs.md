---
plan: drop-unsupervised-docs
urgency: normal
agent: sonnet
effort: high
needs: drop-unsupervised
requirement: none
scope: .agents/docs/unsupervised.md, .agents/docs/orchestrated.md, .agents/docs/consumer-repos.md, .agents/docs/plans/README.md, .agents/docs/product/README.md, .agents/docs/handover/README.md, .agents/docs/subagents.md, .agents/harness/AGENTS.md, .agents/harness/README.md, .claude/commands/upstream-report.md, docs/plans/name-no-consumer-says-both.md, docs/plans/scout-command.md, docs/plans/scout-cycle.md, docs/research/scheduler-outside-the-fleet.md
---

## Goal

Requester, 2026-10-08: "only remove unnecessary stuff." After
`drop-unsupervised` the code has two modes; docs still describe three.
Retire `.agents/docs/unsupervised.md` without losing what still binds.

## Scope

- `.agents/docs/unsupervised.md`: delete. FIRST move into
  `.agents/docs/orchestrated.md`: Bounds (they bind orchestrated today),
  Authority, Heartbeat (a Routine firing `/start` → `/orchestrate`), the
  Runs table (history, kept verbatim), "Not constrained, by decision".
- `.agents/docs/orchestrated.md`: intro and "What the mode changes" table —
  two modes, not "the third value"; every in-file pointer to
  unsupervised.md.
- `.agents/harness/AGENTS.md`: Loop step 2's "ONE difference,
  `JOHARNESS_MODE=unsupervised`" sentence and step 7's "heartbeat under
  unsupervised" — say orchestrated. Caveman style; net size must not grow.
- Every other link to unsupervised.md (`grep -rn unsupervised.md`):
  `.agents/harness/README.md`, `.agents/docs/consumer-repos.md`,
  `.agents/docs/plans/README.md` (Lifecycle "Unsupervised" bullet),
  `.agents/docs/product/README.md`, `.agents/docs/handover/README.md`,
  `.agents/docs/subagents.md`, `.claude/commands/upstream-report.md`.
- Queued `docs/plans/*.md`, `docs/research/*.md` naming unsupervised: fix the
  reference, nothing else.

## Out of scope

- Code and selftests — `drop-unsupervised`.
- `supervised`, `/drain` docs — kept as they are.

## Acceptance

- `grep -rn "unsupervised" .agents docs/plans docs/research .claude` — only
  the Runs table rows and the obsolete-value warning.
- `./joharness.sh ci` — `ci: pass` (anchor lint, instruction size).
- Plan `ci` calls SHIPS: `.agents/docs/consumer-repos.md` names two modes.

## Where to look

- `.agents/docs/unsupervised.md` — what moves.
- `.agents/docs/orchestrated.md` — where it lands.
- `.agents/harness/AGENTS.md` — Loop steps 2 and 7.

## Traps

- Never let style eat a fact (`.agents/docs/caveman.md`).
- A broken link is red in `ci`'s anchor lint.
- Protocol text: `JOHARNESS_MODE=supervised` exported.

---
plan: orchestrated-only-docs
urgency: normal
agent: sonnet
effort: high
needs: orchestrated-only
requirement: none
scope: .agents/docs/unsupervised.md, shared:.agents/docs/orchestrated.md, .agents/docs/consumer-repos.md, .agents/docs/plans/README.md, .agents/docs/product/README.md, .agents/docs/handover/README.md, .agents/docs/subagents.md, .agents/docs/agent-selection.md, shared:.agents/harness/AGENTS.md, .agents/harness/README.md, AGENTS.md, docs/plans, docs/research
---

## Goal

Requester, 2026-10-08: "Only orchestrator mode should be left over."
After `orchestrated-only` the code has one mode, but the docs describe
three. Retire `.agents/docs/unsupervised.md`, keep what still binds, and
make the instruction files describe one mode.

## Scope

- `.agents/docs/unsupervised.md` — delete. FIRST move into
  `.agents/docs/orchestrated.md`: Bounds (as `protocol-boundary-core-only`
  left them), Authority (rewritten for the `authority` verdict
  `orchestrated-only` built), Heartbeat (a Routine firing a fresh session,
  which routes to `/orchestrate`), the Runs table verbatim, and "Not
  constrained, by decision".
- `.agents/docs/orchestrated.md` — the intro and the "What the mode changes"
  table become "how the harness runs". No comparison to other modes.
- `.agents/harness/AGENTS.md` — Loop step 2 (the unsupervised and
  orchestrated sentences, "No issue … ask human"), step 7 ("human
  re-invoking `/drain` under supervised"), and "Decide alone": "stop and
  ask" becomes `status: blocked`, `next:` = the question, push, exit.
  Never wait in session (issue #304). Caveman style. Net size must not
  grow (`ci` context stage).
- Every other link to `unsupervised.md` or mention of supervised mode
  (`git grep -n -i "supervised"`): root `AGENTS.md`, `.agents/harness/README.md`,
  `.agents/docs/consumer-repos.md`, `.agents/docs/plans/README.md`,
  `.agents/docs/product/README.md`, `.agents/docs/handover/README.md`,
  `.agents/docs/subagents.md`, `.agents/docs/agent-selection.md`.
- Queued `docs/plans/*.md`, `docs/research/*.md` naming supervised,
  `JOHARNESS_MODE=supervised` or SUPERVISED ONLY: fix the reference and
  nothing else.

## Out of scope

- Code and selftests (`orchestrated-only`).
- `joharness.conf` comments — a core path, the human's.
- Rewriting history docs beyond moving them (Runs table stays verbatim).

## Acceptance

- `git grep -n -i "unsupervised\|supervised" -- .agents AGENTS.md docs/plans docs/research .claude`
  → only the Runs table rows and the obsolete-key warning's test.
- `./joharness.sh ci` → `ci: pass` (anchors, glossary, context size).
- SHIPS: `.agents/docs/consumer-repos.md` and `.agents/harness/AGENTS.md`
  reach consumers and describe one mode.

## Where to look

- `.agents/docs/unsupervised.md` — what moves.
- `.agents/docs/orchestrated.md` — where it lands.
- `.agents/harness/AGENTS.md` — Loop steps 2 and 7, Decide alone.

## Traps

- Never let style eat a fact (`.agents/docs/caveman.md`).
- A broken link is red in `ci`'s anchor lint.
- `docs/plans` is a whole-directory claim because it fixes references in
  any queued plan. Never touch a plan a manager holds, and leave that one
  for its own PR.

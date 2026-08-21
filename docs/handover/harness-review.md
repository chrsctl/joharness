---
workstream: harness-review
status: review
branch: claude/harness-research-review-l4y9vv
pr: 6
session: https://claude.ai/code/session_01HBRP6Z9bv2vV1tf5yebWvA
agent: sonnet
updated: 2026-08-21
next: Human review + merge PR 8; then fix stale pre-split paths in the three in-flight workstream files (see Blockers)
---

## Goal

Full review of the harness (both layers), research-informed suggestions,
fixes for what the review turned up. Human clarified intent: run agents
fully mobile — each new session gets told entrypoint and model tier up
front, without spelunking.

## Decisions

- New `harness/queue-context.sh` in session-start: prints plan queue from
  origin/main (urgent first, then oldest), each with agent/effort
  frontmatter, plus entrypoint suggestion. That is the mobile flow: hook
  output = what to do + which model.
- `agent:` field added to handover TEMPLATE frontmatter; both hooks surface
  it ("wants opus"), so resuming user picks the right model too.
- New `harness/selftest.sh` wired into `joharness.sh ci` (so GitHub CI runs
  it): harness scripts had zero coverage beyond shellcheck. Git-only, scratch
  repos, 24 checks.
- Scope excludes what in-flight branches own: helm smoke coverage
  (smoke-helm-coverage), K3S_IMAGE bump (k8s-136-validation), sync script
  (harness-sync).
- Researched codejunkie99/graph-engineering (human ask). Task-graph half
  applied: plans get optional `needs:` frontmatter — queue is a DAG,
  blocked while the needed plan file exists (delete-on-merge makes file
  existence the edge, no status field to rot). Hook sorts blocked plans
  last, labels `blocked by:`; unblocked plans = safe parallel sessions.

- Unification research (human ask: "unify both"): knowledge + task graph
  are already one graph here — files as nodes, frontmatter as edges, git as
  provenance, hook injection as 1-hop GraphRAG. Tiers map onto Zep/Graphiti
  agent-memory architecture 1:1: workstream files = episodic, AGENTS.md =
  semantic, docs/ = community summaries; graduation = fusion. Formalizing
  = three candidate steps, in value order: (1) `plan:` frontmatter field in
  workstream files — claim edge machine-readable, queue can mark claimed
  plans (today claim is prose in Goal; two sessions can pick same plan);
  (2) small ontology doc naming node/edge types + carrying field; (3)
  optional `joharness.sh graph` mermaid renderer, derived at read time,
  never stored. 1 + 2 implemented (queue marks `claimed on <branch>`,
  `docs/graph.md`); 3 held until text queue stops being legible.

## Rejected

- Stop-hook enforcement of "update handover before ending turn" — blocking
  Stop hooks need stop_hook_active loop guards and JSON parsing; wrong
  cost/benefit while the discipline works. Revisit if handover files start
  arriving stale.
- Reading GitHub issues in queue-context.sh — shell hook has no `gh` in
  every consumer; queue prints "issues outrank plans" pointer instead.
- refs/claims mutual exclusion — already weighed and rejected in
  docs/handover/README.md; nothing new changes that.
- graph-engineering's knowledge-graph half — a KG of the repo is derived
  state, exactly what the handover protocol's derivability rule forbids.
  Its other task-graph rules (human gate, one writer per file, judge on
  numbers) the harness already implements; nothing to add.

## Blockers

None for this branch. Found, not fixable from here: all three in-flight
workstream files (harness-sync, k8s-136-validation, smoke-helm-coverage)
reference pre-split paths — `scripts/devenv.sh`, `scripts/smoke-test.sh`,
`docs/environment.md` are now `env/k8s/*` and `env/k8s/README.md`. Whoever
resumes those branches: merge main first, fix paths per staleness rule.

## Where to look

- `harness/selftest.sh` — fixture quirk: git drops a directory when a branch
  switch removes its last tracked file; mkdir -p before each heredoc.
- `joharness.sh:cmd_env` — spurious "not usable" fallback warning when
  JOHARNESS_ENV was unset (fixed; selftest covers it).

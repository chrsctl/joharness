---
workstream: base-review-adaptions
status: review
branch: claude/base-review-adaptions-yle8r9
pr: none
plan: none
session: https://claude.ai/code/session_01JWpBo9HoR5Mn1KgqBL6vqt
agent: opus
updated: 2026-08-28
next: Human ratifies or drops docs/plans/moment-feedback-hooks.md; merge deletes THIS file, plan file stays and enters queue
---

## Goal

Human ask: review github.com/ChristopherKahler/base for adaptions.
Reviewed at commit 22e8b8c (basemode v0.13.2): Rust context-injection
engine for Claude Code — stored RDF graph (Oxigraph, NQuads, SPARQL,
tree-sitter AST), four hook injection points, domain rules, session
relay, handoffs, self-update. Review = which mechanisms joharness
adapts, which it rejects under own rules. One proposal graduated to
plan: `docs/plans/moment-feedback-hooks.md`.

## Decisions

- Adapt ONE mechanism: serve context at moment of touch (basemode
  pre-tool triggers, `docs/extensions.md` verify-reflex there).
  joharness serves only at session boundaries — SessionStart injection,
  Stop guard. Steps 4–5 rely on model remembering `feedback <path>`.
  Hook-time serving = stage 4 "Prevent" (`.agents/docs/feedback.md`)
  without model cooperation. Plan filed; human ratifies by merging this
  branch — plan enters queue then, not before.
- Ideas only, never code: basemode license = PolyForm Noncommercial
  1.0.0. Mechanism re-derived from joharness primitives
  (`cmd_feedback`, handover-guard hook pattern). No source copied.
- Dedup design transferable (basemode `once_per_session`): nudge once
  per file per session or nudge gets ignored. Session scratch state,
  never repo state — graph.md no-store rule untouched.
- basemode's own workspace-scoping doc = evidence FOR graph.md's
  no-stored-graph rule: their stored graph self-contaminated (registry
  scan stamped foreign projects into CWD's named graph, every
  session-start re-polluted, operator planned full reset). Failure mode
  derive-at-read-time cannot have. Cite when rule next questioned.
- Depletion-aware re-serving (basemode brackets: reads live transcript,
  measures context depletion, re-injects rules as window fills —
  `src/hook/user_prompt_submit.rs` there) = real gap here: session-start
  injection degrades at compaction. Needs measurement first, and
  transcript parsing is Claude-internals-coupled. Research question, not
  plan; proper shape blocked on `docs/plans/research-node.md`. Recorded,
  not filed.

## Rejected

- Stored knowledge graph, SPARQL, AST extraction, embeddings — graph.md
  Rules forbid all four; substrate here is git, every view derived at
  read time. basemode's contamination incident (Decisions) is the
  measured reason, not taste.
- Cross-session novelty dedup (basemode `.signal-state` hash file) —
  state store, rots; hook already derives "recent" from push time.
- Relay (typed messages, TTL claims, wake sentinel, board) — needs
  shared disk; joharness sessions = isolated remote containers, git the
  only shared substrate. Claim here = pushed workstream file, durable
  and derived. `/who` covers liveness. Their anti-pattern table agrees
  on the one shared point: never model-poll an empty inbox.
- Usage-based staleness GC (`purge --stale`, read renews `lastRead`
  clock) — write-on-read timestamps violate provenance rule (commits
  only, never hand-written time). Delete-on-merge already the lifecycle.
- Silent self-update (background binary swap at session start) — harness
  updates here = instruction changes; land as reviewed `update.yml` PRs.
  Silent rule changes = unreviewed rule changes. Deliberate divergence.
- Star commands, command-plugin dispatcher — `.claude/commands` + skills
  cover the need; no demand.
- Doctor, atomic writes, snapshot rotation — corruption model absent:
  git is the store, commits are the snapshots. `selftest.sh` covers
  invariants.
- Multi-tool portability — no consumer demand. Demand arrives: basemode
  `docs/multi-tool-hook-bible.md` is the map (Codex, Gemini near
  drop-in for shell hooks; Cursor, Windsurf need rules-file generation).
- Env-layer rules injected at PreToolUse — delivery reframe would defeat
  extensions-research's rejection reason ("cannot verify a read
  happened": inject rules, verify nothing). But no measured miss of the
  lazy-md pointer yet. Wait for one.
- Handoff snooze, fork — plans queue + workstream files already carry
  both shapes; snooze = status field to rot.

## Review

- r1: clean pass — docs-only diff (this file + plan file), self-reviewed
  against plans/TEMPLATE.md shape, graph.md rules, caveman.md; anchors
  checked against joharness.sh symbols. (fixed: n/a)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_feedback` — derived per-file findings the plan
  serves at PreToolUse.
- `joharness.sh:fb_collect` — cost comment ("couple of seconds") the
  plan's cache answers.
- `.agents/harness/handover-guard.sh` — hook stdin pattern (grep one
  key, no parser) and fail-open doctrine the plan reuses.
- basemode read checkout was `/home/user/christopherkahler/base` —
  ephemeral; repo + commit named in Goal.

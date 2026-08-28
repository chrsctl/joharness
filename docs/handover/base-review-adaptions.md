---
workstream: base-review-adaptions
status: review
branch: claude/base-review-adaptions-yle8r9
pr: none
plan: none
session: https://claude.ai/code/session_01JWpBo9HoR5Mn1KgqBL6vqt
agent: opus
updated: 2026-08-28
next: Human ratifies or drops docs/plans/moment-feedback-hooks.md; merging the PR puts the plan in the queue
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

Opus adversarial, three lenses (correctness, security, reproduce-the-claim),
2026-08-28. Every finding below is against `docs/plans/moment-feedback-hooks.md`.

- r1: SUPERSEDED, and it was wrong. The pre-opus pass recorded "clean" on
  this diff. The opus pass at the edge found five real defects in the same
  two files. A clean line written by the session that wrote the work is
  worth what this one was worth. (fixed: replaced by r2-r7 below)
- r2: (correctness) plan said the hook prints its report to stdout.
  PreToolUse feeds the model ONLY through
  `hookSpecificOutput.additionalContext` — plain stdout is transcript-only.
  Verified in basemode at 22e8b8c: `src/hook/pre_tool_use.rs:15` says so in
  a comment written after hitting it, `src/hook/mod.rs:141` is the envelope.
  Shipped as written, the hook would look correct in the transcript and
  inject nothing. This repo's SessionStart hook IS plain stdout, which is
  exactly what makes the mistake the default one. (fixed: Scope names the
  envelope, Traps names the trap, selftest pins it)
- r3: (reproduce) plan made the `joharness.sh` quiet shape conditional
  ("only if cmd_feedback needs one"). Ran it: `./joharness.sh feedback
  docs/nope-nothing-here.md` prints a header plus `no merged edge recorded
  a finding whose fix touched this file`, exit 0. So piped raw the hook
  injects a banner before EVERY edit of every file with no findings — the
  common case. Not conditional; required. (fixed: Scope says REQUIRED and
  carries the command that shows it)
- r4: (correctness) plan told the implementer to register the new hook in
  `.agents/scripts/sync-to-consumer.sh`. Read it: `.agents/harness` is a
  whole-tree `DIRS` entry, so a new file there needs no registration, and
  `.agents/scripts` is `CANONICAL_ONLY_DIRS` besides. The line also named a
  path outside the plan's own `scope:` frontmatter. A literal reader would
  have edited a file it must not touch. (fixed: moved to Out of scope,
  Where to look says read-not-edit)
- r5: (security) `session_id` came straight out of hook JSON into the
  scratch directory path. Traversal on a malformed or hostile id. (fixed:
  Scope mandates sanitizing to `[A-Za-z0-9_-]`, acceptance has a `../` case)
- r6: (reproduce) the cache was written as an optimization on the strength
  of a code comment ("costs a couple of seconds"). Measured instead:
  3802 / 3942 / 3783 ms over three runs of `./joharness.sh feedback
  <path>`, this container, 2026-08-28, 61 edges with 50 read. ~4s before
  every Edit and Write makes the cache load-bearing, and the number belongs
  in the plan rather than in a comment. (fixed: Scope carries figure and
  command; acceptance measures first call against second)
- r7: (correctness) `.claude/settings.json` is in the sync `FILES` list, so
  registering the hook ships it to every consumer — unstated in the plan.
  Intended, since stage 4 has to reach consumers, but unnamed alongside the
  ~4s cost it would land there. (fixed: named in Scope)

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

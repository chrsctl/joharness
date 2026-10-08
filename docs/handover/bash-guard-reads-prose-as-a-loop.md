---
workstream: bash-guard-reads-prose-as-a-loop
status: blocked
branch: claude/bash-guard-reads-prose-as-a-loop
pr: none
plan: bash-guard-reads-prose-as-a-loop
issue: none
session: https://claude.ai/code/session_01X7MYq6kL1CgciaSW4PW2fv
agent: opus
updated: 2026-10-08
next: Human — run this node and docs/plans/guard-pairs-done-by-depth.md in a SUPERVISED session; both are all-protocol and no unattended manager can commit the fix.
---

## Goal

Settle `docs/research/bash-guard-reads-prose-as-a-loop.md` and graduate the
answer. Orchestrated manager, one item.

## Decisions

- **Blocked, not attempted.** The node's answer is already settled and
  verifier-grounded in the file. What is owed is the FIX, and the fix is
  protocol text. `./joharness.sh authority` = `orchestrated` + VERIFIABLE,
  so the bound in `.agents/docs/unsupervised.md` (Bounds) applies: protocol
  text is off limits to a session running unattended, wherever it lives.
- **Both ends are protocol, so there is no non-protocol slice to deliver.**
  `./joharness.sh protocol-paths` lists `.agents/harness`. The node's
  `graduates:` is `.agents/harness/pretool-bash-guard.sh`. The fix plan
  `docs/plans/guard-pairs-done-by-depth.md` declares
  `scope: .agents/harness/pretool-bash-guard.sh,
  .agents/harness/selftest/pretool-bash-guard.sh,
  docs/research/bash-guard-reads-prose-as-a-loop.md` — two of three paths
  protocol. Bounds: the handover guard counts ANY protocol path in the diff
  and acceptance is all-or-nothing, so a partly-protocol plan cannot be
  finished either.
- **The node is not deletable yet.** Its own text: the fix plan "deletes this
  node when it lands", and "Nothing lands there until the rewrite". Deleting
  now would drop the measurements that the plan's Acceptance is built on,
  before any fix exists. Retiring it is the plan's last commit, not this
  session's.
- **Taking this node means taking that plan** — the node says so, because a
  research node has no `scope:` for the wave hook to read. So the item as
  dispatched is the all-protocol pair, not a doc-only question.

## Rejected

- **Graduating the answer into the guard.** That is the rewrite itself
  (depth-counting walk, #271's other end). Protocol path — refused by the
  bound, not by difficulty.
- **Writing a fresh plan from the node.** The node forbids it in terms: "no
  plan should be written from it that adds one more test to the walk", and
  the plan that does carry both ends already exists.
- **Annotating the node with this finding instead.** `docs/research/` is not
  protocol, so a note would be committable — but it would not change what
  the orchestrator reads (no respawn gate keys on a research body) and the
  node already predicts the wave-hook half of the gap. Churn, not signal.
  The finding is below instead, where the orchestrator reports it.

## Review

- r1: No diff. Nothing built, nothing to review — `JOHARNESS_REVIEW=off`
  and the edge gate does not fire for a branch with no PR and
  `status: blocked`. (wontfix — no code in this branch by design)

## Blockers

**Blocks:** the fix is protocol text and this session runs unattended.
**Unblocks:** a supervised session (human-directed), which the queue hook
already routes all-protocol plans to — `queue-context.sh:519-521` prints
`SUPERVISED ONLY: scope includes protocol text` for exactly this plan's
class (`some`).

**Finding, and it is the reason a manager was spent here at all —
the protocol boundary is unchecked for research nodes.** A plan with a
protocol path in `scope:` is classified and de-ranked
(`queue-context.sh:402-414` sets `only`/`some`, `:519-523` prints
`SUPERVISED ONLY`). A research node gets no such pass: `qc_print_research`
(`queue-context.sh:625-638`) prints file + label with no boundary class, and
`graduates:` is linted only for existence — `joharness.sh:2626-2641` reds a
missing or typo'd target and warns when it is not in the tree yet, and never
compares it against `protocol_paths`. Grepped 2026-10-08 on this checkout:
`grep -rn 'graduates' .agents/harness/*.sh joharness.sh` returns the two
`queue-context.sh` field/print sites and the `joharness.sh` lint sites above,
and no `protocol_paths` call among them.

Consequence: this node stays a FREE item every dispatch pass, so each pass
spends one manager to re-derive that it cannot be committed. `status:
blocked` here stops the respawn for this node only
(`orchestrate.md:178` — blocked = human's, report, never respawn;
`joharness.sh:8342`), and the gap outlives it for the next such node. Note
this is a DIFFERENT gap from the one the node itself names: the node is about
wave/scope disjointness not seeing node and plan as two items over one file;
this is the supervised-only boundary not being read on a node at all.

**The fix for that gap is also protocol text** (`queue-context.sh` and
`joharness.sh` both listed), so it is not carved out of this blocker — it is
the same supervised session's to take, or its own queue item for one.

## Where to look

- `docs/research/bash-guard-reads-prose-as-a-loop.md` — the settled answer,
  the five measured shapes, and the narrowing that was built and REVERTED.
  Read `## Findings` whole before touching the guard; it is what stops the
  same day being spent twice.
- `docs/plans/guard-pairs-done-by-depth.md` — the fix, both ends, `agent:
  opus` / `effort: high`. Its Goal carries the four payloads with exit codes
  and the two-state history of the guard.
- `.agents/docs/unsupervised.md:63-78` — the bound, and the 55 minutes
  attempt two spent on the all-protocol shape.
- `.agents/harness/queue-context.sh:402-414,519-523,625-638` — where scope
  gets a boundary class and a research node does not.
- `joharness.sh:2626-2641` — the `graduates:` lint, existence only.

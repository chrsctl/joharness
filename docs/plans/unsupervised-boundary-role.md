---
plan: unsupervised-boundary-role
urgency: normal
agent: opus
effort: high
needs: none
requirement: unsupervised-mode
scope: docs/product/unsupervised-mode.md, joharness.sh, .agents/harness/handover-guard.sh, .agents/harness/selftest.sh
---

## Goal

Issue #114. The unsupervised boundary is spelled as ONE path prefix,
`.agents/harness/`, in every place that states or enforces it:
`docs/product/unsupervised-mode.md:44` (the constraint),
`joharness.sh:2991` (the session-start banner), and
`.agents/harness/handover-guard.sh:176-190` (the only thing that actually
detects a crossing — it greps `^\.agents/harness/` and counts).

`.claude/agents/verifier.md` became mandatory protocol text in PR #110: Loop
step 5 requires spawning it, and it is the independent reader the merge gate
leans on. It sits outside that prefix. PR #110 added an assertion that the
file exists (`selftest.sh:1455`), so `ci` is red on deleting that ONE file —
but the guard still sees nothing, the banner still names one tree, and the
next protocol file to land under `.claude/` gets no assertion for free.

The requester decided the shape on 2026-08-28: state the rule by ROLE —
protocol text governing a session is off limits to that session, wherever it
lives — and back it with a path check, so a new protocol tree announces
itself instead of arriving unguarded. Wording alone was declined as
unenforceable; naming both trees alone was declined as stale on the next move.

## Scope

- `docs/product/unsupervised-mode.md` — the Constraints bullet, restated by
  role, with the enumerated trees named as the mechanical expression of it
  rather than as the rule itself.
- `joharness.sh` — one function naming the protocol trees, single source of
  truth. The unsupervised banner reads it instead of a literal.
- `.agents/harness/handover-guard.sh` — detect across every protocol tree,
  not just `.agents/harness`. Keep the count-not-path rule: the reason string
  embeds in JSON unescaped and a file name is repo-controlled input.
- `.agents/harness/selftest.sh` — a crossing in EACH listed tree is detected;
  a tree that ships agent-instruction text and is not listed fails the run.

## Out of scope

- The three limits the requester declined on 2026-08-24 (no cap on work per
  run, no halt when main is red, no ban on sessions spawning sessions). The
  Constraints section records them as declined, and a decomposing session
  must not add them back on its own judgment.
- Turning the guard into prevention. It is a Stop hook: it runs after the
  commit exists, and its own comment says naming an already-crossed boundary
  is the honest thing it can do. Widening WHAT it sees is this plan; changing
  WHEN it fires is not.
- `.agents/env/` — sandbox configuration, not protocol text. A layer does not
  govern a session's behavior, and sweeping it in makes the mode unable to
  provision anything.
- Blocking the merge on a boundary crossing. The mode removes the human,
  never the gate (Constraints), and step 7's conditions stay unchanged.
- Rewriting `.agents/docs/` into the boundary. Those are the reasoning behind
  rules rather than the rules a session executes; widening there is a
  separate decision with its own blast radius.

## Acceptance

- The Constraints bullet states the rule by role, and names the trees as its
  current mechanical expression. Paste the bullet.
- `joharness.sh` has exactly one list of protocol trees. `grep -c` for the
  literal `.claude/agents` outside that function and the docs is 0.
- The banner under `JOHARNESS_MODE=unsupervised` names every listed tree,
  derived from the list, not restated.
- Guard fixture: a branch touching `.claude/agents/verifier.md` under
  unsupervised mode produces the boundary fact. Today it produces nothing —
  assert the before-state in the same case, or the test pins nothing.
- Guard fixture: the same branch under supervised mode produces no boundary
  fact.
- The count stays a count. No path reaches the JSON reason string.
- A tree shipping agent-instruction text and absent from the list fails
  `selftest.sh` by name, with what to add.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 6 passed, 0 failed (this diff touches non-`*.md`
  files under `joharness.sh` and `.agents/harness/`).
- The consumer-side check this plan owes, because `handover-guard.sh` SHIPS
  and `ci`'s ship-scope stage says so: a fixture whose `joharness.sh` has no
  `protocol-trees` subcommand still names the boundary for the historical
  tree, exits clean, and does NOT claim a tree the old list cannot resolve.
  A consumer running an older entrypoint is the realistic case, not a
  hypothetical one — removals never travel, so it is every consumer between
  this merge and its next sync.

## Where to look

- `.agents/harness/handover-guard.sh` — the unsupervised boundary block: the
  `git diff`/`ls-files` fan-in, the `grep -E '^\.agents/harness/'` that is
  the actual boundary, and the count-not-path comment explaining why.
- `joharness.sh:cmd_session_start` — the unsupervised banner and
  `mode_source`, which decides whether the mode came from conf or marker.
- `.agents/harness/selftest.sh:1448` — the existing verifier assertions,
  including the consumer-checkout skip, which is the pattern a new
  canonical-only assertion should follow.
- `docs/product/unsupervised-mode.md` — Constraints, including the declined
  three. Read them before touching the section.
- `.agents/scripts/sync-to-consumer.sh:DIRS` — what actually ships. Useful as
  evidence for which trees are protocol; NOT a substitute for the list, since
  it also ships docs and skills this plan deliberately leaves out.

## Traps

- The guard runs in a CONSUMER too — `handover-guard.sh` ships. A tree that
  exists only in canonical must not make the guard noisy or fatal there.
- Count, never a path, in the reason string. The comment at the guard's own
  fan-in says why: repo-controlled input cannot be allowed to close a JSON
  string. A widened boundary widens what that input could be.
- The working-tree half of the guard is NOT gated on a merge-base. Gating it
  was a measured fail-open — an unattended session on a shallow checkout got
  no boundary at all. Preserve that shape when widening.
- Untracked files count. `git diff` cannot see a file never added, so a new
  protocol file read as absent until the commit the boundary exists to stop.
- `.agents/harness/` names no environment layer, and that holds for any
  fixture added here (`LAYER_CARVE_OUT_*`, one carve-out, spelled once).
- The mode fails closed: anything not exactly `unsupervised` reads
  supervised. A widened boundary must not change that.

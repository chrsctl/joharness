---
plan: hook-unshallow
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/harness/handover-context.sh, .agents/harness/selftest/handover-context-owns.sh
---

## Goal

Every remote session starts on a shallow clone, and the session-start
hook's fetch never unshallows it. `owned_at` then finds no merge-base,
falls back to the tree, and reports every INHERITED workstream file as a
claim. Measured on this checkout 2026-09-03: shallow, the hook led with
`claude/pr-review-cloud-setup-operator-l3lgge` as "FINISH BEFORE
STARTING — at review" and listed 12 entries plus 30 more; that branch is
a strict ancestor of `main` (945 behind, 0 ahead, empty diff) and owns
nothing. After `git fetch --unshallow` (1.3s, 3.8 MiB pack) the same hook
listed 5 entries, the ghost gone. Issue 167 pays for this every session.
Fix the reader, not the branches: the hook unshallows before it reads.

## Scope

- `.agents/harness/handover-context.sh` — in the `HANDOVER_FETCH` block,
  when the clone is shallow, `git fetch --unshallow origin` under its own
  timeout BEFORE the prune fetch. Reword the shallow NOTE so it says the
  hook tried and what to do when it could not.
- `.agents/harness/selftest/handover-context-owns.sh` — a `--depth=1`
  clone of the fixture origin, hook run with `HANDOVER_FETCH=1`: the
  inheritor is demoted and not a claim, no shallow NOTE, clone no longer
  shallow. Must go red with the fetch block reverted.

## Out of scope

- Deleting branches. Human-only (`.agents/docs/product/README.md`, Branch
  flow); issue 167 stays open for that.
- Changing `owned_at`'s tree fallback. It is the right answer when the
  unshallow fails; the fix removes the failure, not the fallback.
- `drain`'s hook call (`DRAIN_FETCH=0`). Same clone, already unshallowed
  by session start; a second network call buys nothing.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- The new selftest case red with the fetch-block change reverted, green
  with it — run both ways, record the command and date in the workstream
  file.

## Where to look

- `.agents/harness/handover-context.sh:owned_at` — the fallback and its
  comment explain why over-report was chosen over a missing claim.
- `.agents/harness/handover-context.sh` line 57 — the fetch block.
- `.agents/harness/selftest/handover-context-owns.sh` — the fixture
  origin `ownorigin.git` is bare, so a `file://` clone with `--depth`
  is honoured (a plain path clone ignores `--depth`).

## Traps

- No commit to protocol text under unsupervised. This session is
  supervised (session start says so).
- Test written for a fix must FAIL without it. Revert, run, put back.
- Measured number carries the command and the date, same sentence.

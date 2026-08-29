---
plan: pr-prioritization
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: .agents/harness/handover-context.sh, .agents/harness/queue-context.sh, .agents/harness/AGENTS.md, .agents/docs/handover/README.md, shared:.agents/harness/selftest.sh
---

## Goal

Human asked whether the harness has anything for prioritizing pull
requests. It does not. Urgency ranking covers work a session would START —
plans, requirements, research questions all carry `urgency`, and
`queue-context.sh` ranks them. Work already IN FLIGHT gets no ranking at
all: `handover-context.sh` lists in-flight branches sorted by
`--sort=-committerdate`, newest push first, which the same hook calls "NOT
liveness — wrong both directions". So the branch closest to merging sorts
by the one signal the hook already disclaims, and a session arriving at the
queue picks a fresh plan while finished work sits unmerged.

Measured on this repo, 2026-08-29, full clone:

```bash
for ref in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin | grep -v HEAD); do
  git merge-base --is-ancestor "$ref" origin/main 2>/dev/null && continue
  base=$(git merge-base "$ref" origin/main) || continue
  for f in $(git diff --name-only --diff-filter=ACMRT "$base" "$ref" -- docs/handover | grep -vE '/(TEMPLATE|README)\.md$'); do
    git show "$ref:$f" | sed -n 's/^pr:[[:space:]]*//p' | head -1
  done
done
```

Six unmerged branches own a workstream file. One is at the edge by `pr:`
(`claude/multi-agent-orchestration-pr-jyli0w`, `pr: 10`), last pushed 8 days
ago, 575 commits behind `main`. Under `-committerdate` it sorts LAST of the
six — and `HANDOVER_MAX_ENTRIES` is 12, so on a repo with a dozen fresher
branches the one piece of work at the edge is the first entry to fall off
the listing entirely. The ordering actively buries what it should lead with.

Two holes, one rule. The rule: **finishing outranks starting**, the same
shape as the existing "planning outranks executing".

## Scope

- `.agents/harness/handover-context.sh` — rank the in-flight listing by how
  close each entry is to merging instead of by push time. Two passes: a
  cheap collect over every ref (status, `pr:`, behind-count, pushed-at),
  then sort by rank, then compute the expensive per-entry extras (overlap,
  churn) only for entries that survive the cap. Stop skipping unmerged
  `status: done`. Lead the block with the entry to finish first.
- `.agents/harness/queue-context.sh` — entrypoint line defers to the
  in-flight block: edge work outranks a fresh plan. Static text only, no
  second ref walk.
- `.agents/harness/AGENTS.md` — Loop step 2 gains the tier.
- `.agents/docs/handover/README.md` — document the rank and what each
  position means.
- `.agents/harness/selftest.sh` — tests for the rank order, the `done`
  un-skip, and the cap interaction.

## Out of scope

- Reading GitHub. `handover-context.sh` reads refs and nothing else, in
  every consumer, on purpose — "one that needed a token to answer would
  fail closed exactly where it matters most". Live PR state (open, checks
  green, mergeable) stays the session's to check. This ranks from git.
- A `./joharness.sh inflight` subcommand. A second implementation of one
  ranking is two readers of one fact, which this repo has already paid for
  once (`owned_at`: "deriving a second one is how two readers of one fact
  start disagreeing"). One implementation, in the hook that already walks
  the refs.
- Triaging or deleting abandoned branches. Deletion is human-only
  (`.agents/docs/product/README.md`, Branch flow). Surfacing is this plan;
  acting on it is not.
- Changing `at_edge` in `joharness.sh`. The rank READS the same two fields
  it does; it does not redefine the edge.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed. SHIPS: the selftest is what a
  consumer runs, so the new tests travel with the sync.
- `bash .agents/harness/handover-context.sh` on a fixture where an old
  `status: done` branch and a fresh `status: in-progress` branch both exist
  — the `done` one prints first.
- `./joharness.sh perf session-start` — under budget (700).

## Where to look

- `.agents/harness/handover-context.sh:owned_at` — ownership, and the
  shallow-clone fallback the rank inherits.
- `.agents/harness/queue-context.sh:qc_edge_unsupervised` — how the queue
  words an entrypoint line.
- `joharness.sh:at_edge` — the edge definition this rank reuses.
- `.agents/harness/selftest.sh:ohook` — fixture style for hook tests.

## Traps

- Sorting after the cap, not before: the cap must bound the RANKED list, or
  the fix reintroduces the bug it removes.
- The claim scan runs for every ref, past the cap. Ranking must not shorten
  it — a missing claim is two sessions duplicating work.
- Measured number carries the command that produced it, same sentence.
- Never kick CI, never skip a test to get green.

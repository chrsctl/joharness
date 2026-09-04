# Prior art

Other systems orchestrate coding agents. This file records what they chose,
what this harness chose, and WHY the difference — for the rejections only.

A rejection with no reasoning does not stay rejected. Session finds the
other system, sees it solves a real problem, re-opens a settled question and
reaches its own answer. That is the failure this file prevents. Not a
feature comparison, not a rival-tool scoreboard: only the arguments a future
session needs to not re-litigate.

Convergences get one line each. Two designs reaching the same rule
separately is evidence for the rule, and evidence is cheap to state.

## Gas Town

[gastownhall/gastown](https://github.com/gastownhall/gastown), Steve Yegge.
MIT License, Copyright (c) 2025 Steve Yegge; the quotations below are short
excerpts of its docs, each with its path, listed in `.agents/NOTICE`.
Reviewed at commit `649b832`, goal-directed: its stated ideas, read from its
own docs. NOT audited — `internal/` Go code, implementation quality, most of
its `docs/design/`. Nothing below rests on running it.
Multi-agent orchestration: tmux-managed
worker fleets ("polecats") in git worktrees, a git-backed issue ledger
(Beads, on Dolt), watchdog agents, a merge queue. Same problem as this
harness — work outliving the session that started it — and nearly every
mechanism differs.

Its docs are the source for every claim below; paths cited are its own, at
that commit.

### Convergent

Arrived at separately, so each is evidence rather than influence.

- **Execute what is assigned, do not wait for confirmation.** Its GUPP
  ("If you find something on your hook, YOU RUN IT.",
  `docs/concepts/propulsion-principle.md`); this harness's Loop steps 1-2
  and `/drain`. Both name the same failure: worker announces itself, waits,
  supervisor assumes progress, nothing happens.
- **Work is not done until pushed.** Its session-completion rule; this
  harness's "no push, no claim".
- **Useful outcomes from unreliable steps need persistent state.** Its NDI
  (`docs/glossary.md`); this harness's file-existence state.

### Rejected: work as a queryable ledger

Gas Town stores every work item as a row in a git-backed database and every
action with an actor, then queries it (`docs/why-these-features.md`: "Work
is data. Not just tickets - structured, queryable data."). Attribution,
agent work histories, audit trails follow from that.

This harness holds the same principle and rejects the datastore. State is
files on branches, read with `git show`. The ledger buys queries; it costs a
database, a daemon and a CLI as install prerequisites for every repo. This
harness is a shell script plus markdown so that a clone, a runner, or CI
carries the whole thing with nothing installed.

Re-open only if a question arrives that files cannot answer — not because
querying looks convenient.

### Rejected: integration branches

Gas Town groups an epic's child work on a shared `integration/<epic>`
branch, landing it to the base branch as one merge commit when all children
close (`docs/concepts/integration-branches.md`). Real gains: children build
on each other, one-commit rollback, CI runs once on combined work.

This harness merges every step to `main` and keeps no long-lived integration
branch. The gains are priced in the two things it optimizes hardest against:
work invisible on `main` for the epic's whole life, and a branch that a dead
session strands. An abandoned integration branch is the abandoned-edge
problem multiplied by its child count.

### Rejected: querying dead sessions

Gas Town discovers previous sessions from event logs and lets a successor
ask a predecessor questions (`gt seance`). It is recovery for what a handoff
failed to carry.

This harness bets the other way: the workstream file carries everything not
derivable from git, written in the same commit as the change, and compaction
decay is measured and designed for rather than patched afterwards. A needed
seance is a workstream file that failed.

This is the strongest challenge to that bet, and the honest re-open
condition: if workstream files are found losing decisions in practice,
reconsider. The mechanism exists; whether it works in practice was NOT
checked — that would need running Gas Town, which this review did not.

### The split under the other differences

Gas Town installs a town on the host and wraps repos as rigs inside it; its
coordination lives in long-running services started by `gt up`. This harness
embeds under `.agents/` in the repo it governs.

That single choice explains most of the rest. Live services can watch,
nudge, queue and schedule; they exist only where someone installed them. An
in-repo harness gets none of that and travels everywhere, including into CI,
where its own gates run. Neither is more correct. Know which trade is being
made before importing a mechanism from a system on the other side of it.

### Their operational scars are evidence for rules here

Gas Town runs on status fields and records what that costs:

- A heartbeat label that "leaves this label stale for hours even though the
  agent is healthy" (`docs/concepts/heartbeats.md`) — a healthy worker read
  as stuck.
- Three heartbeat stores that diverge, so its own rule became: never
  declare an agent stuck from one store, cross-check first.
- Workflow steps materialized as rows, accumulating daily until it stopped
  materializing them (`docs/concepts/molecules.md`).

This harness's "file existence IS the state, so there is no status field to
go stale" predicts all three. Independent confirmation from a system that
paid for it, which is worth more than the rule restated.

### Open, not rejected

- **Merge queue.** Its Refinery batches completed work, verifies the merged
  stack, then bisects a red batch (Bors-style; described in its `README.md`,
  not verified running). This harness serializes instead: each session
  merges its own pull request, 0 behind a fresh-fetched base. A queue would
  remove that reconcile, but the measured failure here is starvation, not
  merge contention — the count and the command that produced it are in
  `.agents/harness/AGENTS.md`, `/drain` paragraph. Adopt only when a
  measurement shows sessions losing time to reconciles, and prefer the
  forge's own merge queue to building one.
- **Merge method is prose here, not a gate.** Step 7 says merge-commit
  method only, because squash or rebase breaks the merged-branch ancestry
  filter. Nothing enforces it: one session squashing once breaks that filter
  for every later session. Gas Town's stated reason for putting its
  equivalent branch rule at the git boundary instead of in role
  instructions — agents can ignore instructions — is the argument for
  closing this. Remedy is a forge setting, not code: restrict allowed merge
  methods on the repo.
- **Liveness for a future heartbeat.** If the unsupervised heartbeat
  ([`unsupervised.md`](unsupervised.md)) ever grows a monitor that judges
  whether a session is alive, take two things from the scars above: never
  declare a worker stuck from one store without cross-checking another
  signal, and Gas Town's health vocabulary (working, idle, stalled, zombie
  for a dead session, plus one for hooked work making no progress) is a
  better starting taxonomy than inventing one.

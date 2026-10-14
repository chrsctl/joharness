# History: handover protocol

Why behind rules in [`../handover/README.md`](../handover/README.md):
measurements, incidents, rejected alternatives. Append-only. Each heading
names the rule and the date its text entered the protocol (`git log -S`).
Moved here 2026-10-14; `git log -p` of both files recovers every sentence.

## Store only what cannot be derived, 2026-10-10

Section "Why not the alternatives", moved whole:

Auto memory (machine-local, empty in a fresh container); one shared
`HANDOVER.md` (conflicts on every parallel branch); uncommitted files (gone
with the container); an issue as ledger (drifts from the diff); a subagent
reconstructing context (findings die with it); `git notes` or event logs
(no human reads them, so none corrects them); interrogating the previous
session (recovery for what the handover failed to carry). Re-open only if
workstream files are found losing decisions in practice.

## Layout, 2026-08-21

Deliberate: repo also carrying `docs/HANDOVER.md`
(common name) collides on case-insensitive filesystem — macOS, Windows —
where `docs/handover.md` and `docs/HANDOVER.md` are same path. Two branches
carrying one each cannot check out on same machine. Directory form immune.

Shared `HANDOVER.md`/`TODO.md` conflicts near every
merge; usual agent resolution — rewrite — silently drops other workstream's
state.

## Review order not gated, 2026-10-10

The ORDER (finding before fix) is not gated: git records what landed in a
commit, not the order it was typed, and a backtest found 2 violations in 535
findings at the cost of flagging four honest branches. The cue stays a
human's.

## In-flight tie order, 2026-08-29

Ties break oldest push first, the inverse of the ref
order this replaced. Within one rank the oldest push is the entry closest to
abandoned, and an abandoned branch at the edge reads as in-flight until a
human triages it ([`../product/README.md`](../product/README.md), Branch flow).

## Liveness looked up, 2026-08-21

Rules out the obvious: registry file on `main` fails like shared `HANDOVER.md`,
worse — most-written file in repo, sessions race, dead session leaves claim
nobody releases.

Measured on one branch, one afternoon:
pushed 5 minutes ago while the session was finished, pushed 3 hours ago while
it was actively working. Wrong both directions.

## Overlap warning instead of a lock, 2026-10-10

Section "If you ever need real mutual exclusion", moved whole:

Above prevents nothing; makes collision visible. Prevention needs lock. Git
provides one, at remote, atomic — `git push` to a ref = compare-and-swap:

```bash
git push origin "HEAD:refs/claims/<workstream>"     # fails if someone holds it
git push origin ":refs/claims/<workstream>"         # release
```

Verified to reject a second claimant, stale `--force-with-lease` included.
Deliberately **not** implemented: the common collision is same files,
different workstreams, which a lock does not prevent and the overlap warning
catches.

## Compaction re-read, 2026-08-29

A compaction summary keeps the task state and
drops the "old" compliance preamble — 0% to 30% violation across 7 models,
8.3x worse for soft organisational policy than for hard safety norms (arXiv
2606.22528).

## Claiming an issue, 2026-08-29

`issue:` exists because two sessions once solved one issue in parallel
because the link lived only in prose.

A padded `#0114` renders fine and still gets duplicated, because a reader
scanning for `#114` does not match it.

Hook silent, `ci` red, so a
malformed claim is loud to its author and invisible to everyone else,
which is the right way round but worth knowing.

The hook reads
refs and nothing else, in every consumer; one that needed a token to
answer would fail closed exactly where it matters most.

## Graduation, 2026-08-21

The "do not bump
`K3S_IMAGE` casually" note in `.agents/env/k8s/AGENTS.md` is exactly this:
rejected approach that graduated.

A rule's story
in `AGENTS.md` is paid by every session that never touches it (one
consumer's `AGENTS.md` reached 93 KB this way).

## Placement, 2026-08-21

Section "Why these things live where they do", moved whole:

Placement decisions that look arbitrary, recorded so not helpfully undone:

- **Loop in `AGENTS.md`, not `docs/WORKFLOW.md`.** Needed every session;
  `AGENTS.md` loads every session. Separate document read once, by the agent
  least needing it.
- **The `main` rot check in the hook, not a test suite.** Suite = one more
  thing to keep in step with file list; hook already fetches and parses these
  files every session start. Costs nothing extra there. `finish` is not a
  second copy of it: the hook reports rot that exists, `finish` refuses rot
  about to be created, and only one of those can still be fixed for free. A
  consumer that made it a suite assertion instead got the third thing — a red
  base branch, which names the problem to everyone and lets nobody fix it
  without another pull request.

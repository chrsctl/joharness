---
plan: queue-shared-scope
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/harness/queue-context.sh, .agents/docs/plans/README.md, .agents/harness/selftest.sh
---

## Goal

The queue partitions free plans into waves of disjoint `scope`, so parallel
safety is proven rather than assumed. In a real consumer queue every plan
that touches code names the same two or three files, so no two plans are
ever disjoint and every wave holds exactly one plan. Measured in
`chrsctl/redocted`: `tests/test_redoct.py` is 8,131 lines and named by 4 of
5 queued plans; `AGENTS.md` and `README.md` by 4 of 5 each; the hook
reported three waves of one.

The advice inverts what the repo did. Four sessions ran concurrently
against exactly those files for 12.5 hours and 2 of 24 pull requests needed
a reconcile merge — an 8% cost, not an impossibility. A session reading the
hook either ignores the mechanism or serialises work that did not need it.

## Scope

- `.agents/docs/plans/README.md` — a `scope` entry may mark a path as
  shared, meaning "a reconcile merge is expected here, not a blocker".
  Spelling is the implementing session's call; record it. Everything
  unmarked keeps today's meaning exactly.
- `.agents/harness/queue-context.sh` — a shared path stops splitting a
  wave. The hook names the expected reconcile instead of collapsing the
  wave to one, so a session reads "parallel, expect a reconcile on
  tests/foo.py" rather than three waves that say nothing.
- `.agents/harness/selftest.sh` — cover both: unmarked overlap still
  splits waves as today, marked overlap does not and the reconcile is
  named in the output.

## Out of scope

- Any change to what `needs` means. Blocking is a different edge and works.
- Guessing shared paths from the tree (file size, extension, an
  append-only heuristic). A declaration is a claim a plan's author makes
  and a reviewer checks; inference would make the queue wrong quietly.
- Splitting consumer test files. That is the real cause in that repo and
  its own work, not this repo's.
- Removing the wave computation. It is right when scopes are genuinely
  disjoint; the fault is that it has no way to express the common case.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — all checks pass, 0 failed.
- Two plans whose only overlap is a path marked shared appear in ONE wave,
  with the expected reconcile named in the hook's output.
- Two plans overlapping on an unmarked path still land in separate waves,
  with the conflict named exactly as today.
- A plan with no `scope` still joins no wave and still says so.

## Where to look

- `.agents/harness/queue-context.sh` — the wave partition and the line
  that names a cross-wave conflict.
- `.agents/docs/plans/README.md`, "Dependencies and parallel work" — where
  `scope` is defined and where the new marking is documented.
- `.agents/harness/selftest.sh`, `== queue-context.sh scope waves` — the
  existing coverage to extend rather than replace.

## Traps

- The queue hook runs before every session's first prompt. Whatever this
  adds to its output must be one line, not a paragraph.
- Caveman style in the README edit: say what the marking MEANS, put the
  reasoning in `.agents/docs/`.
- A wave that claims parallel safety it does not have is worse than one
  that claims none. "Reconcile expected" must read as a cost a session
  accepts, never as "these cannot collide".

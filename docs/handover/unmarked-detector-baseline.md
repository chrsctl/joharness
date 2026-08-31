---
workstream: unmarked-detector-baseline
status: review
branch: claude/unmarked-detector-baseline
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Retire this file, open the pull request, merge.
---

## Goal

Answer the urgent open question `unmarked-detector-unreachable`, implement
the answer, and apply its consequences. The requester delegated the decision
("Continue decide", 2026-08-31); the choice is recorded as ratified in the
requirement rather than made silently in code.

## The decision

**A baseline, not citation dedupe.** `joharness.sh:FB_SINCE` is a literal
commit; findings merged at or before it are history, not the mode's backlog.
Dedupe cannot work — 62 of 155 unmarked findings carry no `rN:` id and no
citation can name them — and the count was otherwise monotonically
non-decreasing, so the sweep could never be dry.

Counted after: `0 unmarked, counted since bcebb325e92f`, and `sweep dry —
every detector zero` for the first time.

## Decisions

- **A literal in a reviewed diff, not a state file.** Same reasoning the perf
  budgets carry: a threshold is a decision, not a measurement, and a baseline
  a session could write is a baseline a session can move to make its own
  backlog disappear.
- **Overridable per repo** (`JOHARNESS_FEEDBACK_SINCE`), because this file
  SHIPS and a canonical sha means nothing in a consumer.
- **An unresolvable baseline counts EVERYTHING, and says so.** Not blind:
  blinding a consumer leaves its sweep permanently INCOMPLETE, the same
  unreachability from the other side. Not zero: that is a dry sweep over a
  backlog nobody bounded.
- **The dedupe plan is retired, not left blocked.** Its mechanism was
  refuted; leaving it would put refuted work back in the queue the moment the
  question closed.
- **Prevention is filed as its own plan.** The baseline moves the starting
  line; keeping the count near zero is Loop step 5's "never drop silent",
  which nothing enforces.

## Rejected

- **Citation dedupe.** Cannot name 62 of 155.
- **Blinding on an unresolvable baseline.** See above.
- **Editing the requirement without recording who ratified it.** The
  amendment names the delegation and its date.

## Review

Round 1, opus, self, with `mutate`.

- r1: **the first version was dry over real backlog.** An unresolvable
  baseline produced an empty set of recent edges, so nothing counted as
  recent and the count read 0 — exactly the failure the change exists to
  prevent, shipped inside the fix for it. My comment claimed the empty case
  "errs toward reporting MORE work", which was the opposite of what the code
  did. Caught by three fixture cases whose repos have no such commit.
  (fixed — `FB_SINCE_OK`, count-everything, and the comment now says what
  happens)
- r2: **the same subshell defect for the third time this session.**
  `src_unmarked` runs inside `$( )`, so the `FB_SINCE_OK` global died before
  `cmd_sources` read it: the count was right and the line under it said "no
  baseline in this repo" about a baseline that resolves. PR 149 was the first
  instance and `.agents/docs/feedback.md` records the class. (fixed —
  `fb_since_ok` is an exit status, not a global)
- r3: adding names to `FB_CACHE_VARS` without adding them to
  `fb_cache_load`'s allowlist made **every cache load fail silently** — a
  failed load is a full re-walk, so the report stays correct and only gets
  slower. Caught by the existing case that empties a cached blob and expects
  the answer to change; with the cache never loading, it did not. (fixed —
  both names added, and a comment saying the two lists move together)
- r4: the baseline cases needed the SAME repo with TWO baselines. One
  fixture with one baseline cannot tell a bound that works from a count that
  happens to be right. (fixed — root and tip, 1 unmarked and 0)
- r5: **this work was done on `main`.** No branch, no claim, no push — steps
  3 and 4, skipped outright. I merged PR 160, checked out `main`, and started
  editing, and only noticed when writing this file's `branch:` field. Nothing
  reached the remote (0 ahead of `origin/main`, changes staged only) so the
  cost was zero, and the rule is not about the times it costs nothing: for
  the whole build no other session could have seen this work, and the branch
  I would have collided with is the one I had just merged. (fixed — branch
  cut carrying the staged tree; the claim is late in exactly the way PR 156's
  r4 was, one merge after I recorded that one)
- r6: verifier round owed and NOT run — standing instruction, nineteenth
  consecutive edge, and the second in a row touching a decision the requester
  delegated to me.

## Verification

- `mutate joharness.sh 2746` (the unresolved-baseline fallback) → reds 5,
  including `and never reads as dry`
- `ci: pass`; `verify` 6 passed, 0 failed; selftest **1089 passed, 0 failed**
- `sources` on this branch: `sweep dry — every detector zero`, and the
  verdict is still `DO NOT STOP` because the queue is not empty — which is
  the stop condition doing its job.

## Blockers

None.

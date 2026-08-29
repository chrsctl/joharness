---
workstream: pr-prioritization
status: review
branch: claude/pr-prioritization-ff09tx
pr: none
plan: pr-prioritization
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-29
next: Open the pull request, then merge it once checks are green
---

## Goal

Human asked whether the harness has anything for prioritizing pull requests.
It does not. Urgency ranking covers work a session would START — plans,
requirements and research questions all carry `urgency`, and
`queue-context.sh` ranks them. Work already in flight got no ranking at all:
the listing was ordered by push time, the one signal the same hook tells its
reader not to trust.

## Decisions

- Rank from git alone, never from GitHub. `handover-context.sh` reads refs
  and nothing else in every consumer; one that needed a token would fail
  closed exactly where it matters most. Live pull request state stays the
  session's to check.
- Rank reads the two fields `joharness.sh:review_at_edge` already reads, and
  redefines neither. A second definition of the edge is two readers of one
  fact, which is how they start disagreeing.
- No `./joharness.sh inflight` subcommand. Same reason: one implementation,
  in the hook that already walks the refs.
- Two passes. Pass 1 is cheap and uncapped so claims stay complete; pass 2
  sorts, caps, and only then pays for the per-ref extras. Capping before the
  sort would hide by push time, which is the bug being removed.
- The lead line names the work and stops. Step 7 gives a session its own pull
  request and no other, so a hook that told every session to merge whatever
  sorted first would order the one thing the Loop forbids.
- Unmerged `status: done` is listed rather than skipped. Merged branches are
  filtered by ancestry one step earlier, so anything still reaching the rank
  is work declared finished that never landed.

## Rejected

- Ranking in `queue-context.sh`. It would need a second walk over every ref
  to answer what `handover-context.sh` answered one script earlier. The queue
  gets a static pointer instead, which costs nothing and cannot drift.
- Tab as the row separator. Tab is IFS whitespace — see r2.

## Review

opus, adversarial, separate lenses (correctness, then perf, then
consumer/security). Findings written before their fixes, committed with them.

- r1: the no-workstream-file row emitted 13 fields where the reader expects
  14 — one separator short between `short` and `fresh`. `fresh` was read as
  `session` and `pushed_rel` as `review_n`, so the entry printed "pushed "
  with no time and never counted toward `recent_count`, which is the only
  reason such a branch is listed. Found by counting separators against the
  read list, reproduced on a scratch fixture. (fixed)
- r2: the row separator was a tab. Tab is IFS whitespace, so `read` collapses
  a run into one and drops every empty field between; every value after an
  unset `pr:` shifted one slot left and the listing printed a session URL
  under "claims issue #". Unit separator instead. (fixed)
- r3: `sort` is not stable and the key list stopped at the timestamp, so two
  branches sharing a rank and a commit second could swap places between runs
  on an unchanged tree. Ref name added as a third key. (fixed)
- r4: the first file-less test used `refute` with a `\n` needle. `expect` and
  `refute` are `grep -F`, so it matched a literal backslash-n and passed
  against the bug it was written for. Caught by running the suite against the
  reverted fix; replaced with an assertion on the extracted line. (fixed)
- r5: `review_n` is now counted for every owned workstream file rather than
  only the listed ones, so a repo with many more in-flight branches than
  `HANDOVER_MAX_ENTRIES` pays one extra awk per file past the cap. Measured
  here with `JOHARNESS_PERF=always ./joharness.sh ci` on 2026-08-29:
  session-start 473 before, 478 after, budget 700. (wontfix — moving it into
  pass 2 trades N awks for 12 `git show`s plus 12 awks, which is not cheaper,
  and the budget has the headroom)
- r6: `pr:` is printed raw after a `#` is stripped, and `ci` does not lint the
  field. Same as `review_at_edge`, which also treats any non-empty non-`none`
  value as the edge and prints it verbatim — matching it is deliberate, since
  a stricter reader here would rank a branch below the edge that `ci` gates as
  at it. Noted, not changed. (wontfix)
- r7: the `.claude/agents/verifier.md` subagent step 5 asks for was NOT
  spawned. This session runs under an instruction not to call the Agent tool
  unless the human asks, and the human asked for research and implementation,
  not for a subagent. The adversarial pass above was run by the session that
  wrote the diff, so the "one reader that did not write it" property is
  missing from this review. Recorded rather than skipped silently. (open)

## Blockers

None.

## Where to look

- `.agents/harness/handover-context.sh:rank_of` — the rank, and why blocked
  is tested first.
- `.agents/harness/handover-context.sh:US` — why the separator is not a tab.
- `.agents/docs/handover/README.md` — the rank table and what each row means.

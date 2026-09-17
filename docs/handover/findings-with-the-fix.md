---
workstream: findings-with-the-fix
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: findings-with-the-fix
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-17
next: Review the withdrawal, then retire this file and open the pull request
---

## Goal

`docs/plans/findings-with-the-fix.md`. Loop step 5 requires a review finding
to be recorded BEFORE its fix and in the SAME commit; nothing checks either
half. The plan conceded the first half is unverifiable from git and proposed
a lint for the second, with one condition on trusting it: a backtest over the
window `feedback` walks, and its own words for what the number decides —
"whether the rule is widely broken (so the check is right and the repo has a
habit to fix) or the check is wrong."

Ran the backtest first, before writing the lint. **The check is wrong.** The
plan is withdrawn on its own decision procedure, the measurement graduates to
`.agents/docs/handover/README.md`, and no code is written.

## Decisions

- Taken at opus, above the plan's `sonnet`. Escalation is allowed; the plan's
  own Traps name the opus condition for exactly this — a gate that cannot
  separate its false positives from the violation is wrong-but-plausible.
- Backtest BEFORE the build, not after. The plan listed it under Acceptance,
  which reads as "build, then measure". Its own sentence says the number
  decides whether the check is right at all, and a check written first is a
  check its author then wants to be right.
- The measurement graduates rather than dying with this branch. A plan for
  this exists because the gap is real and obvious; without a durable record
  the next session proposes it again and re-derives the same 37.
- The plan file is DELETED, not marked blocked. Its question is answered —
  do not build this — and an answered plan left in the queue is work the
  next session picks up and repeats.

## Rejected

- Reusing `joharness.sh:fb_fix_map` as the plan's Where-to-look suggests.
  It already answers "which non-handover paths did this finding's commit
  touch", but it excludes `docs/plans/` and `docs/product/` as well, because
  its job is attributing findings to CODE. For this question a plan-file edit
  IS fix content. Measured on the edge merged as pull request #262:
  `fb_fix_map` over its range returns ZERO pairs, so a lint built on it
  verbatim would have called all eight of that branch's findings recorded
  alone, every one of them wrongly.
- A stricter form keyed on each id's FIRST adding commit, to rule out
  re-adds. Built and run: same 37. The bullets those commits add are
  genuinely new to git — an earlier version of the same finding lacked the
  `r<N>:` id, so `^+- r<N>:` first appears when the id was added.
- `docs/plans/orchestrated-run.md`, which the queue ranks first. Two of its
  preconditions are the human's by its own words, and its one remaining
  deliverable — the Runs row saying what stopped run 3 — needs run 3 to have
  stopped. Re-counted 2026-09-17T01:21Z via `list_sessions` for this
  account: two manager sessions `SESSION_STATUS_RUNNING`, `updated_at` inside
  the last minute.
- The edge branch naming pull request #10. Re-read from GitHub rather than
  inherited: `state: closed`, `merged: false`, closed 2026-08-21. The hook
  says closed and open are the same bytes in git and to check — checked.

## Review

- r1: (session, premise) the plan's premise does not hold, and its own
  backtest is what says so. Counted 2026-09-17 over the newest 50 merged
  edges of `origin/main` — the window `JOHARNESS_FEEDBACK_EDGES` names and
  `feedback` reports as "newest 50 edges of 242, 44 carrying a workstream
  file" — walking each edge's commits for a `- r<N>:` line added by a commit
  touching nothing outside `docs/handover/`: **37 of 532 findings, from
  seven commits, and all seven are a branch obeying another rule.** Four
  recorded a review with nothing to fix (a clean pass, which the protocol
  requires a line for, or findings booked `(open)` before any fix, which the
  template sanctions mid-build). Three rewrote an existing bullet to add the
  `r<N>:` id `lint_finding_ids` asks for or the verdict
  `lint_finding_markers` asks for — new to git, not new as findings. ZERO
  were the shape the rule exists to stop. A gate on that signal fires only
  on branches doing as they are told, which is the precise condition this
  repo's own doctrine says makes a gate stop being read.
  (fixed — the plan is deleted and the measurement graduates to
  `.agents/docs/handover/README.md`, Reviewing, so the gap keeps its
  record and the next session does not re-derive these seven commits.)
- r2: (session, method) the strongest form of the check was built and run
  before concluding, not argued away. Restricting to each id's FIRST adding
  commit returns the same 37. Concluding from the weak form alone would have
  left "you tested a straw version" as the obvious objection, and it would
  have been right.

## Blockers

None.

## Where to look

- `.agents/docs/handover/README.md`, Reviewing — where the measurement
  landed, and the rule it is about.
- `joharness.sh:fb_fix_map` — the mechanism the plan pointed at, and the
  path exclusion that makes it the wrong reader for this question.
- `joharness.sh:fb_edges` — how an edge is enumerated: `--first-parent
  --merges`, second parent, `merge-base m^1 tip`. A backtest that enumerates
  merges any other way walks in-branch reconciles and counts the same
  findings several times; the first run of this one did exactly that and
  reported 86 of 602.

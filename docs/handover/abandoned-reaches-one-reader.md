---
workstream: abandoned-reaches-one-reader
status: in-progress
branch: claude/abandoned-reaches-one-reader
pr: none
plan: none
issue: 279
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-10-07
next: Write the two plans, then verify, review, retire and merge
---

## Goal

Open issues outrank plans and `drain` does not read GitHub. Re-mapped after
PR #302 landed: #249, #251, #254/#257, #258, #267, #271 and #273 all have a
plan or an open question. **#279** (2026-09-17) is the oldest with neither.
Nothing builds unplanned, so decomposing it is this item.

Step 2's first clause is "Finishing outranks starting": the in-flight block
names no `pr:`-bearing entry that is unfinished — the one that did was released
at step 2 under an earlier drain item.

## Decisions

- **Every claim re-measured before planning; all five hold.** Unlike #258,
  whose central claim had gone false, #279's defects are live today:
  - §1, a release reds the branch it releases: **6 of 8** abandoned branches
    carry an enum without the word. Counted 2026-10-07 by
    `git show "origin/$b:joharness.sh" | grep -oE 'lint_enum "\$rel" status[^;]*'`
    over each. `worker-idle-detection-l3v9m3` knows it; the
    `multi-agent-orchestration` branch has no `joharness.sh` at all, so no lint
    runs there. The #294 verifier checked only the first and reasonably
    concluded the defect did not bite — it bites on six others.
  - §2, `cmd_graph` draws a released claim's `claims` edge:
    `awk '/^cmd_graph\(\)/,/^}/' joharness.sh | grep -c abandoned` → **0**, and
    `./joharness.sh graph | grep -c claims` → **7**, including
    `b_unsupervised_boundary`, `b_guard_docs_only_branch`,
    `b_marker_gate_needs_no_done` and `b_unsupervised_endurance`.
  - §3, the hook's row says `claims issue #230` while its own summary says no
    issue is claimed. Observed in THIS session's own session-start output.
  - §5 (from the comment, and the worst): `dispatch_curate_branches` honours
    the word nowhere — `sed -n '/^dispatch_curate_branches()/,/^}/p'
    joharness.sh | grep -c abandoned` → **0** — so releasing a curate claim
    does not free the cycle. It froze one for 18 days.
- **§4 is smaller than filed, and becomes a test rather than a plan.** The
  issue asks whether the STALE marker is load-bearing. It is — it feeds the
  sort key, not only the display (`handover-context.sh:554`). But the
  `abandoned` bracket already demotes those rows by rank 5 (`:469`), so the
  demotion survives. What is live is the consequence the issue names second:
  `./joharness.sh janitor` reads `none — every claim pushed inside 144h` while
  eight abandoned branches exist, so the age window excludes them on age
  grounds and MASKS the `abandoned` filter that should do it. A regression in
  that filter would be invisible for six days. That is one selftest case, not
  a plan.
- **Two plans, split on kind, not on count.** §2, §3 and §5 are one-line
  filters in three readers, matching an idiom `queue-context.sh` already uses
  — one plan. §1 is not a reader to teach but a timing problem with three
  named options and a design choice between code and a sentence — its own
  plan, so the choice is visible rather than buried in a list of filters.
- **`cmd_janitor` DOES honour the word** (`joharness.sh:cmd_janitor`, the
  `[ "$status" = abandoned ] && continue` line), so it is named as the model
  the other readers should match, not as a defect.

## Rejected

- **One plan for all five.** §1's fix is a judgement between three options the
  issue lists; folding it in with four mechanical filters would let an
  implementer take the cheapest without the choice being seen.
- **A plan for §4.** Its stated precondition was checked and the harm it
  predicted is already covered by rank. Inventing work for it would be
  inventing work.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_graph`, `joharness.sh:dispatch_curate_branches` — the two
  readers with zero occurrences of the word.
- `joharness.sh:cmd_janitor` — the reader that gets it right.
- `.agents/harness/queue-context.sh` — the filter idiom to match.
- `.agents/harness/handover-context.sh` — rank 5, and the row label that does
  not apply the test its own summary applies.

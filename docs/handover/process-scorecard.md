---
workstream: process-scorecard
status: review
branch: claude/backpass-usage-review-sbew6t
pr: none
plan: process-scorecard
session: https://claude.ai/code/session_01UcW18iV8drNpkz9rpCT27B
agent: opus
updated: 2026-08-28
next: verify, retire plan + workstream, PR, merge
---

## Goal

Plan `docs/plans/process-scorecard.md`: `ci` counts one process fact — churn —
and every other claim the Loop makes about how a branch behaved is
honour-system. A read-only `scorecard` subcommand reports counted numbers for
the current branch against its merge base. No grade, no store, no gate.

## Decisions

- Plan wants `sonnet`; this session is `opus`. Escalation, allowed.
- DIFF, never the working tree, for the two counts that read workstream
  files. Enumerated from the LOG of `base..HEAD`, not from a `diff base HEAD`:
  a workstream file added and retired on the same branch — every branch that
  follows step 7 — appears in neither endpoint, so an endpoint diff reports
  zero for the branch that obeyed the protocol exactly. Findings for a
  retired file are read from the parent of the commit that removed it.
- A commit touching ONLY `docs/(handover|plans|product)/` is not a code
  commit, and the protocol doc and template under `docs/handover/` are not
  workstream files. Without the second half, touching
  `docs/handover/README.md` launders an off-protocol commit, and the same
  report says there is no workstream file and that every commit touched one.
- `paths touched` counts ALL paths, protocol paths included. The line says
  paths. The churn line names its own exclusion in the label, because the two
  numbers sit two lines apart on different filters.
- `base_ref()`, not a hardcoded `origin/main`: `graph` and `feedback` already
  resolve the base branch that way, and a repo with a local `main` and no
  remote is measurable.
- Commit boundaries come from a `\001%H` marker, NOT blank lines. Measured
  2026-08-28 on git 2.43.0 (`git --version`), `git log --no-merges
  --no-renames --format= --name-only HEAD~3..HEAD | cat -A` in this repo
  emits no blank line at all, so blank-line counting would have read 0
  commits for every branch. `churn_top`'s comment claimed the opposite; it is
  corrected in the same commit, because `joharness.sh` is in this plan's
  scope and the correction would otherwise live only in this file, which step
  7 deletes.
- Numbers reproduced by hand, 2026-08-28, `b="$(git merge-base HEAD
  origin/main)"` → `1e895a9`:
  - commits — `git rev-list --no-merges --count "$b"..HEAD` → 3, scorecard 3
  - paths — `git log --no-merges --no-renames --format= --name-only "$b"..HEAD
    | sort -u | grep -c .` → 4, scorecard 4
  - workstream files — same log, `-- docs/handover`, `sort -u | grep -c .`
    → 1, scorecard 1
  - retirements — `git diff --name-only --diff-filter=D "$b" HEAD --
    docs/plans docs/product | wc -l` → 0, scorecard 0
  The first cut of this list recorded `commits → 2`, which was already 3 when
  it was written. Caught by review, not by me.
- This branch scores 1 off-protocol commit, and that is `b1aa97f`: it changed
  `joharness.sh`, `.agents/harness/selftest.sh` and `.agents/docs/graph.md`
  without updating this file in the same commit, against step 6. Left standing
  rather than rewritten — history is the record — and named here because the
  first thing the tool measured was its author breaking the rule it counts.
- Step 4 requires `./joharness.sh feedback <path>` on the files the diff will
  touch. Not run before writing the first cut. `feedback joharness.sh` returns
  16 edges, four of them the tree-vs-diff class, and it would have caught r1
  before it was written. Run now, and the finding stands as evidence the step
  is load-bearing rather than ceremonial.

## Rejected

- Reusing `lint_nodes docs/handover`, as `review_report` does. It reads the
  working TREE, so a branch inherits every workstream file its base branch
  carries and scores the accretion as its own compliance — in the flattering
  direction, and worst on exactly the consumer the plan's Goal cites, where
  23 stale files would read as 23 of this branch's own.
- Widening `churn_top`'s protocol-path filter to serve the new counts. The
  plan forbids it and the filter is what keeps protocol commits out of the
  churn gate that already ships. `sc_walk` is a second walk over the same
  range with its own classification.

## Review

Opus tier, adversarial, two lenses on the full branch diff.

- r1 TREE, NOT DIFF. `workstream files` and `review findings` read the
  working tree via `lint_nodes`, so files inherited from the base branch and
  untracked files counted as this branch's. A base branch carrying three
  stale workstream files with three findings each scored a branch that owns
  none as 3 and 9. This repo's highest-recurring defect class
  (`docs/plans/tree-vs-diff-rule.md`, four merged edges), and the guard on
  `origin/main` that reads the diff instead names THIS plan in its comment.
  Both lenses opened on it. (fixed — log of `base..HEAD`)
- r2 And the mirror image: at the one moment the numbers matter — step 7's
  retirement commit — the tree holds nothing, so the branch that followed the
  protocol exactly scored 0 workstream files and 0 findings, with both
  accusing zero-messages firing. The first fix, an endpoint `diff base HEAD`,
  ALSO failed this: a file added and deleted on the same branch is in neither
  endpoint. Caught by the test written for it. (fixed — log enumeration plus
  reading a retired file from the deleting commit's parent)
- r3 A failed or truncated walk printed a short count as a measured one:
  `sc_walk`'s rc was discarded twice, by `$( )` and by the heredoc, and
  `${commits:-0}` turned "no data" into a measured-looking 0. Corrupt one
  tree object and a 5-commit branch read 1, exit 0. (fixed — rc checked, line
  count checked, no counts rather than short ones)
- r4 `docs/handover/README.md` laundered an off-protocol commit: the
  workstream test matched the whole directory, so the same report said there
  was no workstream file and that every commit touched one. (fixed)
- r5 The retirement counter counted `README.md`, `TEMPLATE.md`, `VISION.md`
  and files in subdirectories as retired nodes, and MISSED a real one whose
  name is non-ASCII — git C-quotes the path, so `"docs/plans/caf\303\251.md"`
  matches no prefix test. (fixed — `-c core.quotePath=false`, `-z`, and the
  same node vocabulary `lint_nodes` uses)
- r6 The same C-quoting made a non-ASCII workstream file compliant to one
  counter and off-protocol to another, in one report. (fixed)
- r7 `most-touched file` printed `churn_top`'s number with its exclusion
  stripped, so on this very branch it named `joharness.sh` at 1 while the
  actual most-touched path was the workstream file at 2. The bare number also
  carried no unit. (fixed — the label names the exclusion, the number names
  its unit)
- r8 Hardcoded `origin/main` instead of `base_ref()`, which `graph` and
  `feedback` both use: a repo with a local `main` and no remote read
  "not measurable" and printed a header naming a ref that does not exist. The
  test written for it locked the wrong behaviour in. (fixed — both)
- r9 FABRICATED VERSION. The comment and this file said the blank-line
  measurement was taken on "git 2.55". `git --version` here is 2.43.0. The
  behaviour was measured and real; the version was decoration, and it shipped
  to every consumer. (fixed — the measured version, and the command beside
  it)
- r10 The recorded hand-reproduction said `commits → 2`; it was 3 at the
  commit that wrote it. The one artefact meant to prove the counts was itself
  an unreproducible written number, which fails the plan's acceptance
  criterion outright. (fixed — re-measured, with the merge-base named)
- r11 `0  (none — legitimate only on a copy or sync branch)` — "legitimate"
  is an adjective doing evaluative work, the plan says no adjective, and the
  list was narrower than the protocol's and contradicted `review_report`'s
  version two lines away in the same file. (fixed — points at the protocol,
  states no list)
- r12 The comment block restated the plan's Goal, including "23 stale
  workstream files" with no command and no date — a permanent third copy in
  the file every consumer receives. (fixed — points at step 7, which carries
  the count)
- r13 The `graph.md` addition led with a claim that was false for two of the
  five things it listed, restated "derived at read time" for the third time
  in one short file, and carried a rationale with an expiry date. (fixed —
  two lines)
- r14 TEN mutations survived the first suite, including deleting
  `--no-merges`, deleting `--no-renames`, swapping the plans and requirements
  counters, saturating the workstream count at 1, and dropping the `## Review`
  scoping that makes a finding a finding. Every one had the same cause: one
  fixture, one of everything. (fixed — the fixture now has an inherited file,
  two workstream files with different counts, one plan and TWO requirements,
  non-node files beside them, a rename, a merge commit, bullets in three
  sections, and a non-ASCII name)
- r15 `--no-merges` means a change living only in a merge commit is invisible.
  Kept: it is `churn_top`'s frame and the printed line says so. Pinned by a
  test, so a silent change becomes a red run rather than a different metric
  under the same label. (wontfix — recorded, and the line discloses it)

## Blockers

None.

## Where to look

- `joharness.sh:churn_top` — the merge-base walk to reuse, with the
  `docs/(handover|plans|product)/` exclusion and the reason for it.
- `joharness.sh:base_ref` — where the base branch is resolved, once.
- `joharness.sh:cmd_graph` — the precedent for a read-time derived view.

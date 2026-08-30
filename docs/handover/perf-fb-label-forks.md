---
workstream: perf-fb-label-forks
status: review
branch: claude/perf-fb-label-forks
pr: none
plan: perf-window-fixed-cost
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Merge once green; the ceiling stays at 300 until several merges have been sampled
---

## Goal

Took `perf-window-fixed-cost` and did the candidate its corrected plan marks
"take this one": `fb_label` spent a `git log -1` and a `sed` per edge asking
for a merge subject that `fb_edges` had already walked past.

Also repairs a regression this session merged in #140: the Python that
rewrote the plan's Goal rebuilt the file from `## Goal` onward and dropped the
entire frontmatter block.

## Decisions

- Subject carried as a THIRD field from `fb_edges`, tab-separated, taken as
  everything after the first tab so a subject containing one survives whole.
- `fb_label` parses with shell builtins, no fork at all. `##` not `#`, so the
  last occurrence wins — the sed it replaces anchored on a greedy `.*`, which
  also takes the last.
- Ceiling NOT lowered, against this plan's own acceptance text. One
  post-change measurement cannot size a band, and lowering onto an unsampled
  band is exactly the mistake #138 fixed. The condition for lowering is
  recorded beside the number instead.
- Plan retired. Its Goal was the per-edge cost cut and that is delivered;
  what remains is a measurement over several merges, not a build, and a plan
  whose build is done invites the next session to build it again.

## Rejected

- Folding `sort -u` into the awk in `fb_workstream`, the other fork-per-edge
  candidate. Selection among candidate workstream files is by sorted order and
  2 of 51 edges carry two, so order-of-appearance would change which document
  is scored. Left named in the plan's history as a trap.

## Review

opus, adversarial. Lenses: did the refactor change behaviour, is the new
coupling pinned, and is the ceiling decision honest.

- r1: `cl_merged_claims` reads `while read -r m tip` and `read` puts the
  remainder in the last variable, so a third field would have landed INSIDE
  `tip` and computed a merge base against "<parent> <subject>" — silently, on
  every edge. Found by grepping `fb_edges` callers before changing its
  contract rather than after. Changed to `read -r m tip _`. (fixed)
- r2: verified the refactor is behaviour-preserving by diffing `feedback`
  output against `origin/main` on the same commit — byte-identical, not
  eyeballed. (no action)
- r3: my first version of the new selftest cases asserted against an unpushed
  fixture. `feedback` walks `base_ref`, which is `origin/main` in that
  fixture, and the `edge` helper above pushes after every merge; mine did not,
  so three cases failed while the code was right. A test that fails for its
  own setup teaches nothing about the code. (fixed)
- r4: the refute in those cases used a bare `PR` needle over the whole output,
  which can never pass — earlier fixture edges are numbered and print `PR4`
  and `PR6` correctly. Scoped to the single line carrying the unnumbered
  finding. Same class as the `DRAINED`-inside-`NOT DRAINED` bug earlier this
  session: a substring needle that matches something legitimate. (fixed)
- r5: checked both new couplings fail when reverted. Dropping the subject from
  `fb_edges` reds the label case; dropping the `_` in `cl_merged_claims` reds
  three EXISTING cleanup cases, so that corruption was already covered. (no
  action)
- r6: the frontmatter loss in #140 passed `ci` because `lint_enum` returns 0
  on an empty value, so a plan with no frontmatter is linted as clean. Queued
  as `lint-plan-frontmatter` rather than fixed here — it is a separate guard,
  and widening this diff to cover it would bury the perf change. (open)

## Blockers

None.

## Where to look

- `joharness.sh:fb_edges` — the third field and why callers must read it.
- `joharness.sh:fb_label` — the fork-free parse.
- `joharness.sh:perf_rows` — the measurements and why 300 stays.

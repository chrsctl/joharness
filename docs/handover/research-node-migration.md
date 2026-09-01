---
workstream: research-node-migration
status: in-progress
branch: claude/research-node-migration
pr: none
plan: research-nodes-red-a-clean-consumer
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-09-01
next: Implement frontmatter-presence node rule; verify against gx both ways; open PR
---

## Goal

The harness sync reds a clean consumer: gx was `ci: pass` before, `ci: FAIL`
(65 DEAD, 13 files x 5 keys) after, entirely because `docs/research/` now
schedules on frontmatter those documents predate. Measured on
chrsctl/gx#226.

## Decisions

- **A research node is a file whose frontmatter block is present (first
  line `---`). A file without one is a plain document: not scheduled, not
  linted.** Confirmed against gx: all 13 offending files open with a `#`
  heading, none with `---`.
- **Diverges from the plan's recommendation (candidate 2, an explicit
  opt-out marker).** Candidate 2 costs every consumer a one-line edit per
  pre-existing document, forever — a migration burden pushed onto every
  repo. Frontmatter-presence costs nothing: gx goes green on the sync
  alone.
- **The escape-by-omission trap is answered, not ignored.** To escape the
  queue a real node would have to delete its *entire* frontmatter identity
  — not "forget a key" — which also strips claimability and scheduling.
  That is a legibly-not-a-node document sitting in the directory, not a
  silently dropped finding. A node that HAS `---` but forgot a key stays
  DEAD: the gate the plan needs is preserved exactly.
- **Scoped to `docs/research/` only.** `docs/plans/` and `docs/handover/`
  hold nothing but nodes; a frontmatter-less file there is malformed and
  must still red, so the filter is NOT applied to them — a second arg opts
  research in.

## Rejected

- Candidate 1 as the plan framed it ("no frontmatter = not a node,
  globally"). Applied to plans/handover it would hide a malformed node.
  Scoping the rule to research is what makes it safe.

## Review

`/code-review high` on the full diff; five findings, all triaged.

- r1: the queue test captured `out` with PLAIN-DOC present, then removed the
  document and pushed but never re-read, so the following blocked-plan and
  2-free-plans assertions measured a fixture state no longer on the ref.
  (fixed — re-capture `out="$(rq)"` after the revert, restoring the state
  those assertions were written against.)
- r2: the filters strip a trailing `\r` before comparing to `---`, which the
  awk parsers (`fields`, `gr_fields`) do not. (wontfix — the strip is the
  established convention for first-line frontmatter detection in this file:
  `lint_unknown_types` strips it too, "a CRLF checkout is a checkout, not a
  different repo". Keeping it leaves a CRLF-corrupted `---\r` node a
  node-candidate that the parser then reds for unreadable keys — fail-loud —
  where dropping the strip would misclassify it as a plain document and
  silently exempt it. The lenient classifier is deliberate.)
- r3: each research file is `git show`n twice — once for line 1 in
  `frontmatter_only`, again for the whole document in the rrows loop.
  (wontfix — research dirs are small (gx's largest consumer has 13) and
  queue-context sits at 202-209 against a 350 budget with room to spare;
  threading the read through the filter pipe to save one object read per
  file trades clarity for I/O the budget does not need.)
- r4: the "first line is `---`" rule now lives at four sites — two awk
  parsers and two shell filters. (wontfix — the two access methods differ
  irreducibly (working-tree read in shell for the lint, `git show` for the
  hook) and the awk parsers answer a different question (parse the fields)
  than the filters (is this a node at all); one helper cannot span both. r2
  settles the one place they could disagree.)
- r5: `frontmatter_only`'s comment said the unreadable detector "counts and
  names" a kept file, but `qc_warn_research_unreadable` prints only a count.
  (fixed — comment now says "counts it (as a number, not by name)".)
- r6: verifier not spawned by this session. This is the divergence the last
  edge (#181 r3) flagged — the instruction forbids calling the Agent tool
  unasked, and Loop step 5 asks for a reader that did not write the diff.
  (wontfix — issue #168, the human's to lift; the code-review pass above is
  the closest available substitute and ran as a fork.)

## Blockers

None.

## Where to look

- `joharness.sh:lint_nodes` — optional frontmatter filter, research passes it.
- `.agents/harness/queue-context.sh:queue_files` — mirror filter for research.
- `.agents/docs/research/README.md` — states which files are nodes.

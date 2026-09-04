---
plan: attribution-correctness
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .agents/docs/caveman.md, .agents/docs/prior-art.md, .agents/docs/product/README.md, .agents/docs/graph.md, .agents/docs/handover/README.md, .agents/docs/unsupervised.md, .agents/docs/consumer-repos.md, .agents/NOTICE, .agents/harness/selftest/license-notice.sh
---

## Goal

Two asks after #206 shipped the notice. First, verbatim: "Can we Attribute
correctly" — MIT names the copyright notice AND the permission notice as
what travels with every copy, and `.agents/docs/caveman.md` carried only the
first, pointing at a neighbouring file for the second. Second, verbatim:
"Okay remove mention and just integrate The ideas" — `.agents/docs/prior-art.md`
recorded another project's design by name and quotation; the arguments this
repo actually needs are its own and belong in the documents that own each
decision.

## Scope

- `.agents/docs/caveman.md` — closing `## Upstream license` section with
  the upstream MIT notice verbatim. Header drops the carry-the-license-with-it
  clause and points at that section.
- `.agents/docs/prior-art.md` — deleted. Its load-bearing arguments move:
  - `.agents/docs/product/README.md` — the integration-branch trade
    (replacing the link to the deleted file), the merge-method gap and its
    forge-setting remedy, the merge-queue question and what would justify
    one.
  - `.agents/docs/graph.md` — why the queue is files rather than a
    queryable store, and what an in-repo harness trades away by having no
    long-running service.
  - `.agents/docs/handover/README.md` — interrogating a dead session, as a
    row in the alternatives table, with the re-open condition.
  - `.agents/docs/unsupervised.md` — what a liveness monitor would owe if
    one is ever added.
  - `.agents/docs/consumer-repos.md` — a migration section: removals do not
    travel, so a consumer synced before this change keeps the deleted file
    while its NOTICE loses the entry covering that file's quotations. One
    `git rm`, with the reason it is worth running.
- `.agents/NOTICE` — the caveman entry says the notice is reproduced in the
  file; the entry for the deleted file goes with it.
- `.agents/harness/selftest/license-notice.sh` — assert both halves of the
  upstream notice in `caveman.md`, grant and disclaimer separately.

## Out of scope

- The one-line source credit in `.agents/docs/graph.md` for the task-graph
  model it adapts. It is provenance for the document's whole framing, not a
  quotation, and removing it would make the file less honest, not more.
- Any change to root `LICENSE` or `.agents/LICENSE`.
- Carrying another project's measured failures forward without their source.
  Claims that hold only because someone else measured them are dropped, not
  restated unsourced — this repo does not assert numbers it never counted.

## Acceptance

- `grep -c 'Permission is hereby granted' .agents/docs/caveman.md` — `1`.
- `grep -c 'THE SOFTWARE IS PROVIDED "AS IS"' .agents/docs/caveman.md` — `1`.
- `git grep -l 'prior-art' -- '*.md' '*.sh'` — no hit outside `docs/`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- SHIPS: every path above reaches consumers at the next sync. Consumer-side
  check: the two greps in the consumer tree after `./joharness.sh upgrade`.

## Where to look

- `.agents/docs/product/README.md` — Branch flow, the bullet that held the
  pointer.
- `.agents/harness/selftest/license-notice.sh` — the existing copyright
  assertion; the two new ones sit beside it.

## Traps

- The permission text is byte-exact MIT; caveman style never touches quoted
  license text.
- Retire this plan and the workstream file in the last commit BEFORE the
  pull request opens.

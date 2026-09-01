---
plan: research-nodes-red-a-clean-consumer
urgency: urgent
agent: opus
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/docs/research, .agents/docs/consumer-repos.md, .agents/harness/selftest
---

## Goal

Measured 2026-08-31 syncing `chrsctl/gx` (`847f64e`), both directions on one
branch:

| | DEAD lines | `ci` |
| --- | --- | --- |
| gx pre-sync | **0** | **pass** |
| gx post-sync | **65** | **FAIL** |

All 65 are 13 files x 5 missing frontmatter keys, **entirely** inside
`docs/research/`. Nothing else in a 27-updated/7-new sync fails anything.

**The sync turns a green consumer red**, over files that consumer had
before the research-node protocol existed, and offers it no way out. The
pre-`.agents` move had a documented migration (`consumer-repos.md`,
*Migration*); this one has none.

## Why the obvious fix is wrong

"Add the frontmatter." Those are the consumer's own domain documents, and
several are **answered history rather than open questions** —
`POSTGRES-STACK-2026.md` opens with *"its findings were taken; ADR 0085
turned §1's verdicts into decisions"*. `graduates:` names where an answer
lands. Writing it for 13 documents nobody in canonical understands
fabricates exactly the metadata the queue then schedules on, which is the
written-number failure in a different coat.

## The real tension, stated

`lint_graph`'s own message is right: *"an absent key reads as a default
rather than as a mistake"*. That is why a research node missing `agent:`
is DEAD rather than defaulted.

But it does not distinguish two different things:

- a **research node** that forgot a key — genuinely broken, must stay red;
- a **document that merely lives in `docs/research/`** and was never a
  queue node at all.

Making "no frontmatter at all" mean "not a node" is the obvious lever and
it is not free: it hands any real node an escape hatch — omit the whole
block and leave the queue. That is the same absent-is-not-empty failure,
pointed the other way. **This is the decision the plan exists to make, not
one to make in passing.**

Candidates, with the objection to each:

1. **No frontmatter at all = not a node.** Simple, migrates every consumer
   for free. Escape hatch above.
2. **An explicit opt-out marker** in the file. No escape by omission; costs
   every consumer a one-line edit per file, which is a migration but a
   mechanical one.
3. **A directory-level opt-in** (`docs/research/` is scheduled only if some
   marker file exists). Cleanest for consumers, worst for discoverability —
   a repo could hold real nodes nothing schedules.
4. **Warn, never red, for a file with no frontmatter**, red once it has
   any. Degrades like the shallow-history case `lint_graph` already has a
   precedent for. Weakest gate.
5. **Routing decides nodehood** (human proposal, 2026-09-01): a file in
   `docs/research/` is a node when the graph routes through it — it
   self-names (`research: <stem>` as its first frontmatter key, the node
   definition `lint_unknown_types` already counts on) OR an open plan's
   `research:` edge names its stem. gx's 13 files do neither, so they read
   as documents and the sync lands green with zero consumer migration —
   the one cost candidate 2 cannot avoid. A node a plan is waiting on that
   drops its whole frontmatter block STAYS a node, because the plan's edge
   convicts it — candidate 1's escape hatch closes wherever anything
   references the file. Objection: an UNREFERENCED node that loses its
   entire block leaves the queue silently, the PR 140 shape again — and an
   open question no plan names yet is a normal state here, not a corner.
   Narrower hole than 1's, wider than 2's none.

Recommendation: **5**, with **2** as the fallback if the unreferenced-node
hole is judged disqualifying. 5 is the only candidate that both migrates
every consumer for free and keeps a referenced node from escaping by
omission; 2 remains the only one with no hole at all, at the price of a
per-file edit in every consumer.
Decide from the candidates rather than inheriting this line.

## Scope

- Pick one and implement it in `lint_graph`.
- A `Migration` section in `.agents/docs/consumer-repos.md`, matching the
  pre-`.agents` one: what a consumer runs once, and what the warning says
  until it lands.
- `.agents/docs/research/README.md` states which files in the directory are
  nodes and which are not.

## Out of scope

- Authoring frontmatter for any consumer's documents.
- Changing what a research node means once it IS one.
- Filtering by file TYPE — not a lever. `lint_nodes` already reads only
  `*.md` minus TEMPLATE/README/VISION, and `gr_docs` keeps only `.md`
  minus TEMPLATE/README; every one of gx's 65 DEAD lines is a `.md` file,
  so ignoring non-markdown or meta files fixes nothing here.

## Acceptance

- A consumer whose `docs/research/` predates the protocol syncs to a GREEN
  `ci`, reproduced against gx's 13 files as the fixture case.
- A real research node missing a key is still DEAD.
- Whichever candidate is chosen, the escape-by-omission case has a test
  that fails without the fix. Candidate 5 chosen? The test pins the
  referenced half — a plan-named research file with no frontmatter is
  DEAD — and the unreferenced hole is written down in
  `.agents/docs/research/README.md`, not left implicit.
- `mutate` reds them.

## Traps

- gx's `ci` was green before the sync and red after. Any fix claiming to
  solve this must be checked **both ways against that same tree**, not
  against a fixture built to pass.
- Do not widen `gr_docs`' exclusion list to paper over it — `README.md` and
  `TEMPLATE.md` are excluded because they are the protocol's own files, not
  because they are inconvenient.

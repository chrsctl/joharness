---
plan: plan-ship-scope
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/docs/plans/README.md, .agents/docs/plans/TEMPLATE.md, .agents/harness/selftest.sh
---

## Goal

In a consumer, a plan's diff stays in that repo. Here it does not: this repo
IS the harness, so most plans edit files the sync engine ships to every
consumer. Classifying each queued plan's `scope:` against the sync lists
(`.agents/scripts/sync-to-consumer.sh` `FILES`/`DIRS`/`CANONICAL_ONLY`,
2026-08-28, throwaway script over `docs/plans/*.md`): **9 of 10 plans touch
at least one shipping path**; only `fanout-live-run` (`docs/product/`,
`docs/research/`) does not. Nine plans whose merge lands in every consumer's
next sync, and nothing in the plan shape says so.

Two plans already reinvented the reasoning in prose, each for its own scope:
`docs/plans/selftest-split.md:38` ("Without this one line every topic file
ships to every consumer") and `docs/plans/moment-feedback-hooks.md:56`
("registering here ships the hook to every consumer, where it fires on every
edit against that repo's own merged history"). Same reasoning, twice,
independently. `.agents/docs/feedback.md` calls that graduation: a rule
nobody wrote yet.

The cost when it is not written: `docs/plans/finding-id-lint.md` scopes
`joharness.sh` and `.agents/docs/handover/TEMPLATE.md` — both ship — and its
Acceptance names only local `selftest.sh` and `ci`. Its stage will run in
every consumer against that repo's own workstream files, and its `TEMPLATE.md`
rewrite becomes a requirement for every child repo's sessions. The plan is not
wrong. The shape never asked.

## Scope

- `joharness.sh` — a classifier that reads each plan's `scope:` frontmatter
  and reports `ships` or `canonical-only`, by matching paths against the sync
  engine's own lists. Surfaced as a `ci` stage. WARN only, never red.
  Canonical-only behavior: silent in a consumer, for the reason under Traps.
- `.agents/docs/plans/TEMPLATE.md` — a shipping plan's Acceptance names the
  consumer-side check: the sync `--dry-run` (`.agents/docs/consumer-repos.md`),
  or the "does the child run it?" test `CANONICAL_ONLY` already applies.
- `.agents/docs/plans/README.md` — one paragraph: what the label means, and
  why it is derived rather than declared.
- `.agents/harness/selftest.sh` — fixtures: a plan scoping only `docs/`, one
  scoping `joharness.sh`, one scoping `.agents/harness/selftest.sh`
  (canonical-only inside a shipping tree), one using `shared:`, one with
  `scope: none`.

## Out of scope

- Splitting `docs/plans/` into framework and local subdirectories. That
  duplicates a boundary `.agents/scripts/sync-to-consumer.sh` already owns,
  giving two answers to "does this ship" that disagree the first time a path
  moves between lists. The directory split is already clean and already
  enforced — `docs/` is in neither `FILES` nor `DIRS`, and
  `bootstrap-consumer.sh` strips joharness's plans from a new consumer.
  Location is not the gap; blast radius is.
- A new frontmatter field (`ships: yes`). Field discipline fails exactly when
  someone hurries — the reason plans carry no `status` field
  (`.agents/docs/plans/README.md`, Lifecycle). Derive it from `scope:`, which
  the queue hook already reads and which rots visibly in review.
- Copying `FILES`/`DIRS` into `joharness.sh`. A second copy of the boundary is
  the precise defect this plan exists to avoid creating.
- Failing `ci`. Report first, same reasoning `finding-id-lint` gives for its
  own stage: a gate with no backtest that reds a working branch is a gate
  sessions route around. A later plan gates it if the label proves out.
- Changing what actually ships. The classifier reads the lists; it never
  edits them, and it does not adjudicate whether a path SHOULD ship.
- Retro-labelling merged plans. Done plans are deleted on merge and survive
  only in history.

## Acceptance

- Assert on fixtures, not on the live queue. The live count moves as plans
  merge and as `CANONICAL_ONLY` grows, so a hard-coded 9-of-10 rots; the
  fixtures do not. Same reasoning as `finding-id-lint`'s Acceptance.
- The stage names a plan, its verdict, and the specific path that earned it.
  Paste the output.
- A plan scoping only `docs/` reports `canonical-only`, not `ships`.
- `.agents/harness/selftest.sh` under a shipping `.agents/harness` tree
  reports `canonical-only` — the `CANONICAL_ONLY` exemption beats the `DIRS`
  prefix. Get this backwards and every selftest plan is mislabelled.
- `shared:` is stripped before matching; `scope: none` produces no verdict,
  not a false `canonical-only`.
- Run against the live queue once and record the output in the workstream
  file, as a sanity check that is expected to drift — not as an assertion.
  It should flag `selftest-split` on `.agents/harness/selftest/`, which is
  the leak that plan's own prose warns about and adds a guard for. The
  classifier finding it independently is the evidence the label is worth
  printing.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
- `./joharness.sh ci` — `ci: pass`, green on a branch whose plans all ship.

## Where to look

- `.agents/scripts/sync-to-consumer.sh:FILES` / `:DIRS` /
  `:CANONICAL_ONLY` / `:CANONICAL_ONLY_DIRS` — the single source of truth.
  Parse these; do not restate them.
- `joharness.sh:cmd_upgrade` — the `grep -q '^JOHARNESS_CANONICAL=1' "$CONF"`
  idiom for "am I canonical", already used to refuse a consumer-only command.
- `joharness.sh:lint_nodes` — how an existing stage enumerates `docs/plans`,
  and `lint_anchors` next to it for how a plan's body is already read.
- `.agents/harness/README.md` — the one-sentence ownership boundary
  (`.agents/` + `.claude/` + root instruction files + `joharness.sh` =
  harness, `docs/` = yours). The classifier is that sentence, executable.
- `.agents/docs/feedback.md` — stage 4, Prevent, and the graduation rule this
  plan is an instance of.

## Traps

- `.agents/scripts/` is `CANONICAL_ONLY_DIRS` — it does NOT exist in a
  consumer. `joharness.sh` ships; the file it must read to classify does not.
  Degrade silent there, never die. A consumer needs no verdict anyway: its
  plans ship nowhere.
- Read the plan's declared `scope:`, never a branch diff. Most queued plans
  have no branch yet. This is not the tree-or-diff rule
  (`.agents/harness/AGENTS.md` step 4) — that governs file ownership on a
  branch; here the frontmatter is the input by construction.
- A `DIRS` tree ships whole EXCEPT its `CANONICAL_ONLY` entries.
  `.agents/harness/selftest.sh` is exempt today; `.agents/harness/selftest/`
  is not. That asymmetry is live, and closing it is `selftest-split`'s work,
  not this plan's. Reflect the lists as they are, never as a plan intends
  them to become.
- `scope` is only as true as it is complete (`.agents/docs/plans/README.md`).
  A verdict derived from an incomplete scope is confidently wrong, so the
  stage reports what the scope SAYS and never implies the scope is right.
- Never rewrite an existing plan to make its verdict nicer.

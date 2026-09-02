---
plan: mark-mixed-protocol-scope
urgency: normal
agent: opus
effort: high
needs: none
requirement: unsupervised-mode
advances: No unsupervised session commits protocol text
scope: .agents/harness/queue-context.sh, .agents/harness/selftest/queue-context-supervised-only.sh
---

## Goal

The queue marks a plan `SUPERVISED ONLY` when EVERY path in its `scope:`
is protocol text. `.agents/harness/handover-guard.sh` blocks a session's
stop when the branch touches ANY protocol path. A plan with one protocol
path and one other therefore passes the queue and trips the guard — it is
dispatched to an unattended fleet and cannot be finished by it.

Measured 2026-09-02 on `main` f9fb932: `docs/plans/unsupervised-drain-only.md`
declares `scope: joharness.sh, ..., docs/product/unsupervised-mode.md, ...`,
`JOHARNESS_RUN_MODE=unsupervised bash .agents/harness/queue-context.sh`
lists it with no marking, and `JOHARNESS_MODE=unsupervised ./joharness.sh
drain` answers `next: docs/plans/unsupervised-drain-only.md`. Its own Traps
say "Supervised session only".

**This reverses a deliberate decision, and the reversal is the plan.** The
comment above `qc_scope_class` and the case "a mixed scope is not marked"
(fixture `joharness.sh, docs/product/thing.md`) argue a mixed plan "is not
undoable: the session does that part and records the remainder". That
premise assumes partial credit the Loop does not model:
`.agents/docs/plans/README.md` says "Acceptance — commands with expected
output. All pass or not done", step 5 says all green or not done, and step
7 deletes the plan file only when it is done. A session that does the
non-protocol half passes no acceptance, deletes no plan file, and hands off
— which is what attempt two did, and what
`docs/product/unsupervised-mode.md` calls the failure: "the queue offered
an unsupervised fleet a plan it could never finish". A mixed plan cannot be
finished unattended either. The line is drawn at "can it be started" where
the requirement draws it at "can it be finished".

## Scope

- `.agents/harness/queue-context.sh` — `qc_scope_class`: keep the three
  classes but change what the counts mean. `only` when every declared path
  is protocol text (unchanged), a new `some` when at least one is and at
  least one is not, `unknown` when nothing is declared (unchanged). The
  row loop marks and de-ranks `only` AND `some`; labels stay distinct so
  the output still says which shape it is:
  - `only` → `, SUPERVISED ONLY: scope is all protocol text` (unchanged
    bytes)
  - `some` → `, SUPERVISED ONLY: scope includes protocol text`
  `unknown` keeps its note and its no-de-rank, for the reason already
  written there: guessing is out of scope.
- `.agents/harness/queue-context.sh` — the comment block above
  `qc_scope_class` (the three-answer list) and the file header comment
  (`SUPERVISED ONLY` when every path in `scope:` is protocol text) both
  state the old rule and get rewritten to the new one, with the reason
  from this Goal — the guard fires on ANY, so the queue marks on ANY.
- `.agents/harness/selftest/queue-context-supervised-only.sh` — the block
  "partial overlap is a different case" inverts: its comment carries the
  new reasoning, `refute "a mixed scope is not marked"` becomes an expect
  for `SUPERVISED ONLY: scope includes protocol text`, and the two
  assertions under it ("and stays free work", "so the edge is not reached
  over it") flip to their marked equivalents. Add one case that the
  all-protocol label is still the `is all` wording, so the two shapes
  cannot collapse into one string.

## Out of scope

- `handover-guard.sh`, `joharness.sh:protocol_paths`. The guard is the
  half that is already right; this plan moves the queue to agree with it.
- The `unknown` class. A plan that declares no scope stays unmarked and
  un-de-ranked; guessing is still out of scope, and this plan changes
  nothing about that.
- Supervised output. The marking is called only under unsupervised and
  this plan does not move that condition. The requirement's
  byte-identical bullet is pinned by `queue-context-edge.sh`'s `eq_same`
  and must stay green.
- `docs/plans/unsupervised-drain-only.md`'s own content. Correcting it is
  the other half of this branch and is a stale-plan fix in place
  (`.agents/docs/plans/README.md`), not this plan's scope.
- Any change to how `shared:` is stripped, how globs are refused, or how
  `none` is read. Those cases stay green untouched.

## Acceptance

- `./joharness.sh ci` — `ci: pass`, `<N> passed, 0 failed`.
- `./joharness.sh verify` — `0 failed`.
- `JOHARNESS_RUN_MODE=unsupervised bash .agents/harness/queue-context.sh`
  on this repo — the row for `docs/plans/unsupervised-drain-only.md`
  carries `SUPERVISED ONLY: scope includes protocol text`; the rows for
  `advance-feedback-baseline.md` and `gate-review-verifier-tag.md` keep
  `scope is all protocol text`, byte-identical to today.
- `JOHARNESS_MODE=unsupervised ./joharness.sh drain` on this repo — does
  NOT answer `next: docs/plans/unsupervised-drain-only.md`, and names it
  under the SUPERVISED ONLY block instead.
- `diff <(JOHARNESS_RUN_MODE=supervised bash .agents/harness/queue-context.sh) <(JOHARNESS_RUN_MODE=supervised git stash ... )`
  is NOT the bar; supervised is pinned by the suite instead: every case in
  `queue-context-supervised-only.sh` asserting supervised output stays
  green untouched, and `queue-context-edge.sh`'s `eq_same` cases stay
  green.
- The inverted case FAILS with the `qc_scope_class` change reverted and
  passes with it back (step 5: green both ways pins nothing).
- SHIPS (`.agents/harness/` syncs to every consumer): a consumer whose
  plan declares one protocol path and one other sees it marked and
  de-ranked under unsupervised after its next sync; `./joharness.sh ci`
  passes there.

## Where to look

- `.agents/harness/queue-context.sh:qc_scope_class` — the `seen`/
  `protocol` counters and the final `if`; the whole change is that
  comparison and the label it selects.
- `.agents/harness/queue-context.sh` — the row loop's `case "$qc_class"`,
  which is where `some` joins `only`.
- `.agents/harness/handover-guard.sh` — `harness_touched`, the ANY-path
  count this plan makes the queue agree with.
- `.agents/harness/selftest/queue-context-supervised-only.sh` — the
  block "partial overlap is a different case", and `soplan`/`soq` above
  it.
- `docs/product/unsupervised-mode.md` — "the queue offered an unsupervised
  fleet a plan it could never finish", the sentence this plan reads as
  the rule.

## Traps

- Protocol text: `.agents/harness/` is in `protocol_paths`. Supervised
  session only. This plan is marked `SUPERVISED ONLY` by its own change
  once it lands, which is the point.
- Do not widen the marking to `unknown`. Absent is not empty runs both
  ways: it is not proof of protocol text either.
- The label strings are read by `joharness.sh:drain_supervised_only`,
  which greps `SUPERVISED ONLY` on the row. Both labels contain it; check
  `drain` output, not only the hook's.
- Supervised output byte-identical. The marking is unsupervised-only
  today and stays that way; do not move the call site out of its
  condition while editing it.
- Never delete a case to get green. The inverted case replaces the old
  one because its subject changed, not because it failed.

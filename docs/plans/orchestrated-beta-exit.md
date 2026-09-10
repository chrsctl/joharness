---
plan: orchestrated-beta-exit
urgency: normal
agent: sonnet
effort: high
needs: orchestrated-run
requirement: orchestrated-mode
scope: joharness.sh, .agents/docs/orchestrated.md, .agents/docs/unsupervised.md, .agents/harness, .claude/commands, .agents/scripts
---

## Goal

Requester, 2026-09-10: move orchestrated mode out of beta. The word is not
decoration — it is a claim about evidence, written once
(`.agents/docs/orchestrated.md:16`): "beta until a run shows which empties a
queue faster." Fourteen sites repeat the label; this plan strips them once
the sentence that licenses the label stops being true, and not before.

## The gate — read this before touching a file

The label comes off when the Runs table in `.agents/docs/orchestrated.md`
carries a row satisfying the LAST `Satisfied when` bullet of
`docs/product/orchestrated-mode.md`: started once over a stocked queue,
every free plan the queue held at start merged, no human turn, under the
cap, numbers counted.

State when this plan was written, so the next reader starts from facts:

- Run 1 (2026-09-06, consumer `chrsctl/gx`) does NOT satisfy it, in its own
  words: "Nothing stopped it; the queue did not drain" — 30 plans waiting
  at the end, ended by a human turn, which `orchestrated-run.md` makes the
  end of the measurement by rule.
- Run 2 was in flight at one observation (2026-09-07) and its row is not
  written.
- The two defects run 1 filed are fixed and retired on `main`
  (`e1ec240`, `8e637aa`), as are `orchestrator-edge-slot-leak` (`dd0cbf2`)
  and `stillborn-manager` (`dec09da`). Open defects are NOT what blocks
  this plan. The missing drain number is.

`needs: orchestrated-run` encodes it: that plan owns the run and the row,
and this file stays blocked while it exists.

Gate reads false and a human has still ratified the strip? That is product
direction and theirs to give (`.agents/harness/AGENTS.md`, Decide alone).
Record the ratification and its date in the same commit, and change
`.agents/docs/orchestrated.md:16` to say what the label rests on now —
never delete the sentence and leave the claim unsourced.

## Scope

Fourteen sites, counted `git grep -n '(beta)\|beta default\|beta loop\|beta run\|beta until'`
on this branch, 2026-09-10. Strip the label, keep every sentence's meaning:

- `.agents/docs/orchestrated.md:1` — title.
- `.agents/docs/orchestrated.md:16` — the licensing sentence. Rewrite to
  name the run that discharged it, with its date. This is the ONE site
  that carries reasoning; the other thirteen are labels.
- `.agents/docs/unsupervised.md:17` — "A third value, `orchestrated` (beta)".
- `joharness.sh:84` — usage block.
- `joharness.sh:268` — `run_mode` comment.
- `joharness.sh:5606` — "else the beta default", a knob comment.
- `joharness.sh:5868` — "the beta loop by hand", a `dispatch` comment.
- `joharness.sh:6642` — the session-start banner string.
- `.agents/harness/selftest/orchestrated.sh:75` — asserts that banner
  LITERALLY. Same commit as the banner or the suite reds.
- `.agents/harness/AGENTS.md:51` — Loop step 2.
- `.agents/harness/README.md:32` — the docs index row.
- `.claude/commands/orchestrate.md:5`, `manage.md:5`,
  `upstream-report.md:5` — the three role headers.
- `.agents/scripts/conf-keys.sh:48` — the key's one-line gloss, which
  reaches consumers through sync.
- `.agents/scripts/bootstrap-consumer.sh:417`, `:490` — interview text.

## Out of scope

- `docs/product/orchestrated-mode.md:14`. That "(beta)" is inside the
  requester's transcribed words and is a record of what was asked, not a
  label on the mode. A session writes no requirement of its own and does
  not edit one to read better.
- Deleting `docs/product/orchestrated-mode.md`. `orchestrated-run.md` owns
  that deletion when every bullet reads true.
- `.agents/harness/selftest/dispatch.sh:801` — "for a human running the
  beta loop" quotes an earlier draft in a comment explaining a rejected
  wording. Quoting it is the point.
- Making orchestrated the default mode anywhere: not the conf's value, not
  `run_mode`'s fail-closed fallback, not the consumer bootstrap. Out of
  beta is a claim about evidence; default is a separate decision the
  requester has not made (asked 2026-09-10, answered with this ask
  instead).
- Changing any behaviour. This plan moves words. A code change found
  necessary is a finding and a new plan.

## Acceptance

- `git grep -n 'beta' -- joharness.sh .agents .claude | grep -v 'alpha beta\|alphabeta' | grep -v 'selftest/dispatch.sh:801'`
  — no hit naming orchestrated mode.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed. The diff touches non-`*.md` files
  under `joharness.sh`, `.agents/harness/` and `.agents/scripts/`, so step
  7 requires it.
- `.agents/harness/selftest/orchestrated.sh` green with the banner's new
  string, and RED against the old one — revert the banner alone and watch
  it fail, or the assertion pins nothing.
- `.agents/docs/orchestrated.md:16` names, in one sentence, the run and
  date the label rested on and what discharged it.
- `ci` calls SHIPS: `.agents/scripts/conf-keys.sh` and
  `bootstrap-consumer.sh` are in the diff, so consumers read this wording
  at their next sync.

## Where to look

- `.agents/docs/orchestrated.md:Runs` — the table whose row is the gate.
- `docs/product/orchestrated-mode.md:Satisfied when` — the four bullets.
- `docs/plans/orchestrated-run.md:Acceptance` — what the run must produce.
- `joharness.sh:run_mode` — the fail-closed switch. Unchanged by this plan.
- `.agents/harness/selftest/orchestrated.sh` — the banner assertion.

## Traps

- Protocol paths are in `scope`, so this plan is `SUPERVISED ONLY`: a
  session running unattended may not commit it
  (`./joharness.sh protocol-paths`).
- Banner and its assertion in one commit. Split, and the suite reds on a
  commit that is correct.
- The label is a claim. Stripping it while the Runs table still says the
  queue never drained makes this repo assert something it measured false.
- Trust counted numbers, never written numbers — including the fourteen in
  this file. Re-run the grep.

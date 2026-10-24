---
plan: hold-requirement
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: halt-and-hold
issue: none
scope: shared:joharness.sh, .agents/harness/queue-context.sh, .agents/harness/selftest/dispatch-order.sh, .agents/harness/selftest/queue-context.sh, .agents/harness/selftest/ci-graph-lint.sh, .agents/docs/product/README.md, .agents/docs/product/TEMPLATE.md, .agents/docs/graph.md
---

## Goal

A human wants an unplanned requirement built only after another item lands,
or not yet at all, without it taking a planning slot. Only plan frontmatter
has `needs:`; a requirement has `requirement` and `priority`, so the gx
orchestrator held one in its own ledger (`humanhold=<stem>`), which dispatch
cannot read. This plan gives a requirement two optional frontmatter fields,
read from the base branch like every other edge: `needs: <stem>[, <stem>]`
(deferred: held while any named item file exists on the base) and `hold:
<reason>` (held until the human removes the line). While held the
requirement is listed, never offered, and holds no slot; once the named item
is gone it is offered again with no edit (`docs/product/halt-and-hold.md`,
Satisfied when, clauses 2 to 4).

## Scope

- `.agents/harness/queue-context.sh` — the `unplanned=` block: read `needs`
  and `hold` beside `priority` with `fields`. For each `needs` stem (comma
  or space separated, `stem` applied, `none` skipped) that exists on `$ref`
  as `docs/plans/<s>.md`, `docs/research/<s>.md` or `docs/product/<s>.md`,
  in that order, append it to a `blockers` list; a stem absent from all
  three is no blocker (merged, satisfied or a typo: `ci` says which). `hold`
  present and not `none` = held. Label: `[<priority>, UNPLANNED — decompose
  into plans<, blocked by: <stems>><, held><, claimed on <branch>>]`;
  the words `blocked by:` and `held` are the only new tokens, the reason
  text is never printed (branch- and base-controlled text in a label is
  how a claim was forged once: verifier r6 comment between `rprio=` and
  its `case` guard). Rank
  `+4` when blocked or held, as a blocked plan ranks. `unplanned_free`
  excludes rows carrying `blocked by:` or `held` as it excludes `claimed on`,
  so every sentence that sends a session to planning skips them.
- `joharness.sh` — `drain_requirement`: skip lines carrying `blocked by:`
  or `, held` as it skips `claimed on`. `cmd_dispatch`: after the spawn
  list and before the `NOT YOURS — CORE ONLY` block, when the hook listed a
  withheld requirement, print `withheld  : <path> — held: <reason>` or
  `withheld  : <path> — blocked by: <stems>` (both when both), one line per
  requirement; `<reason>` = `gr_field hold` of
  `refs/remotes/origin/<base>:<path>`, passed through
  `tr -cd 'A-Za-z0-9 ._:#/()-'` and cut at 80 characters; `<stems>` from the
  label. Silent when none. The verdict word is unchanged: a queue holding
  only withheld requirements is `DRAINED`, the line beneath it says what
  waits. `lint_graph`, the `docs/product` loop: `needs:` stems resolve as the
  plan loop's do, against all three directories — exists = fine;
  `lint_existed` on any of the three = fine (the edge cleared);
  `lint_shallow` = `lint_warn … unknown here (shallow history)`; else
  `lint_red "${rel}: needs '<n>' — no such plan, question or requirement,
  never existed. Typo?"`. `hold:` any value, no check. A requirement with
  `needs:` or `hold:` that an open plan's `requirement:` names =
  `lint_warn "${rel}: held, but planned — its plans run regardless; the hold
  withholds planning only"`.
- `.agents/docs/product/README.md` and `.agents/docs/product/TEMPLATE.md`
  — README "## Requirements": the frontmatter sentence names `needs` and
  `hold` as optional; one bullet **Held** after **Unplanned**: what each
  field does, read from the base, no slot, offered again without an edit
  once the named item is gone; a `hold` clears only by edit; neither
  touches the requirement's plans. "Intake facts": a `needs:` naming a stem
  that never existed reds `ci`; one that existed and is gone holds nothing.
  TEMPLATE frontmatter gains `needs: none` and `hold: none` with one
  comment line each inside the existing HTML comment.
- `.agents/docs/graph.md` — the `needs` edge row: `plan → plan;
  requirement → plan, research or requirement`, same open-target rule.
- `.agents/harness/selftest/dispatch-order.sh` — cases after the
  `claimedreq` block, each requirement written with a `qoreq`-style helper
  that takes extra frontmatter lines:
  1. `hold: until the gx migration lands` alone on main: `dispatch` prints
     no `— UNPLANNED:` spawn line, `verdict   : DRAINED`, `slots     : 4 of
     4 free`, and `withheld  : docs/product/<r>.md — held: until the gx
     migration lands`. Remove the line, push: offered again.
  2. `needs: gate` with `docs/plans/gate.md` on main: not offered, `withheld
     … blocked by: gate`; `fixture_rm` the plan, push, no edit to the
     requirement: offered (`— UNPLANNED: one planning manager`).
  3. `needs: gatereq` naming another requirement: held while
     `docs/product/gatereq.md` exists, offered once it is deleted.
  4. Composition (clause 2 of the requirement): a held requirement whose
     planning branch reads `status: abandoned` (reuse `qoreqclaim <stem>
     abandoned`): still not offered, `4 of 4 free`, no in-flight row.
  5. A held requirement that a plan names in `requirement:`: no `withheld`
     line for it (not UNPLANNED, the hold is moot), the plan offered.
- `.agents/harness/selftest/queue-context.sh` — one `priority: normal`
  requirement with `hold:` and one with `needs:` naming an existing plan,
  beside `unplanned-req`: rows read `[normal, UNPLANNED — decompose into
  plans, held]` and `[…, blocked by: <stem>]`; with `unplanned-req`
  removed so every unplanned requirement is withheld, the output carries
  neither `Plus one planning session for the UNPLANNED requirements above`
  nor `then UNPLANNED requirements above` (the fixture holds plans, so
  `plan the requirements above` never prints there: refuting it proves
  nothing). Read the topic header first: it shares a chain and a fixture
  (`SELFTEST_CHAINS`), so set every precondition the case turns on and
  restore `unplanned-req` after.
- `.agents/harness/selftest/ci-graph-lint.sh` — `needs: nosuch` on a
  requirement reds with `no such plan, question or requirement`; `needs:
  <an existing plan>` and `hold: any words here` pass; `needs:` naming a
  plan that existed and was deleted (the `gone-req` fixture pattern) does
  not red; a held requirement an open plan names draws the
  `held, but planned` warning.

## Assumptions

- A1: the queue hook is the only producer of requirement rows and `drain_requirement` the only consumer that offers one — evidence: `.agents/harness/queue-context.sh` `unplanned=` block; `joharness.sh:drain_requirement` (`sed -n '/^Requirements without plans/,/^$/p'`), called once in `cmd_dispatch` — confidence: high
- A2: `unplanned_free` is what every "go plan" sentence in the hook reads — evidence: `.agents/harness/queue-context.sh`, the comment above `unplanned_free=` (verifier r4) — confidence: high
- A3: a label token is trusted downstream, so free text must not enter it — evidence: `.agents/harness/queue-context.sh` comment below `rprio=` ("forged a planner in flight (verifier r6)"); `joharness.sh:cmd_dispatch` cuts the branch out of a label with `branch="${label##*claimed on }"` — confidence: high
- A4: `lint_existed` answers "did this path ever exist on this history" for any path — evidence: `joharness.sh:lint_existed`; the plan loop's `needs` arm calls it on `docs/plans/<n>.md` — confidence: high
- A5: `gr_fields`/`fields` read a frontmatter key once, comment after ` #` stripped — evidence: `joharness.sh:gr_fields`; `.agents/harness/queue-context.sh:fields` — confidence: high
- A6: a requirement with open plans is not in the `unplanned` list at all — evidence: `.agents/harness/queue-context.sh`, `grep -qxF -- "$rs" <<<"$served" && continue` — confidence: high
- A7: `lint_unknown_types` reads only the second frontmatter line and warns on a self-naming key with no type doc; `needs`/`hold` on line 3+ of a requirement are invisible to it — evidence: `joharness.sh:lint_unknown_types`, `read -r l1; read -r l2` — confidence: high

## Out of scope

- A hold on a plan. Plans have `needs:`; a human hold on a plan is a
  different requirement.
- A plan's `needs:` naming a requirement or research file. The plan `needs`
  edge stays plan to plan (`lint_graph` plan loop untouched).
- Printing the `hold:` reason inside the hook's row label (A3). The reason
  prints on dispatch's `withheld` line, read from the base branch by
  dispatch itself.
- A new `priority` value. `priority` stays `normal | urgent`.
- Halting a live claim (`docs/plans/halt-claim.md`). Case 4 writes
  `status: abandoned` into the fixture directly, as the existing
  `qoreqclaim claimedreq abandoned` case does.
- An orchestrator ledger key. The hold is in the file on the base branch;
  dispatch reads git.
- A core path (`./joharness.sh protocol-paths`). None is touched.

## Acceptance

- `./joharness.sh ci` — last line `ci: pass`.
- `./joharness.sh verify` — the layer prints `0 failed`.
- `JOHARNESS_SELFTEST_JOBS=1 .agents/harness/selftest.sh 2>&1 | sed -n '/^== joharness.sh dispatch: order$/,/^== /p' | grep -c 'withheld'` — at least `5` (one PASS label, `and its requirement stays withheld`, exists today; the new cases add at least four whose labels name `withheld`), and the range's `grep -c '^  FAIL'` is `0`.
- `JOHARNESS_SELFTEST_JOBS=1 .agents/harness/selftest.sh 2>&1 | grep -c '^  FAIL'` — `0`.
- On a scratch checkout of this branch: write `docs/product/x.md` with `needs: nosuch` beside `requirement: x` and `priority: normal`; `./joharness.sh ci 2>&1 | grep -c "needs 'nosuch' — no such plan, question or requirement"` — `1`.
- SHIPS (`joharness.sh`, `.agents/harness/queue-context.sh` and the three `.agents/docs/` files reach every consumer; the selftest files do not): in a consumer checkout with one requirement carrying `hold: paused`, `./joharness.sh dispatch 2>&1 | grep -c 'withheld  : docs/product/'` — `1`, and the same output `grep -c 'UNPLANNED: one planning manager'` — `0`.

## Where to look

- `.agents/harness/queue-context.sh` — the `unplanned=` block (`rprio`, `rqclaimed`, the label `printf`) and `unplanned_free=`; the plan rows' `blockers` loop above it is the shape the `needs` loop copies.
- `joharness.sh:drain_requirement` — the one offering reader; the `grep -v 'claimed on '` line is where the two new tokens join.
- `joharness.sh:cmd_dispatch` — `req="$(drain_requirement …)"`, the `spawn, in this order` block, `drain_core_only` and the `NOT YOURS` block the `withheld` lines precede.
- `joharness.sh:lint_graph` — the plan loop's `needs` arm (the resolution to copy) and the `docs/product` loop (where it lands).
- `joharness.sh:lint_existed` — history test for a cleared edge.
- `.agents/harness/selftest/dispatch-order.sh` — `qoreq`, `qoreqclaim`, `qo`, `qofirst`, `fixture_rm`; the `claimedreq` cases the new ones follow.
- `.agents/harness/selftest/queue-context.sh` — `unplanned-req` and `served-req` fixtures and their `UNPLANNED` row assertions.
- `.agents/harness/selftest/ci-graph-lint.sh` — the `gone-req` and `claim-goal` fixtures.
- `.agents/docs/product/README.md` — "## Requirements" bullets and "Intake facts".

## Traps

- Never a core path: `joharness.conf`, `.claude/settings.json`, `.github` stay untouched.
- Never skip, disable or quarantine a test.
- Label tokens are vocabulary: `blocked by:` and `held` only; never the `hold:` text, never a stem that fails `stem`'s charset.
- Caveman and status quo in the docs: the rule and the mechanism, no gx story (it lives in the requirement and git log). Glossary (`ci` reds banned spellings): "workstream file", never "handover file".
- `ci` reds a plan or requirement whose frontmatter breaks an enum; `priority` keeps its two values.
- The selftest `queue-context` topic shares a chain (`SELFTEST_CHAINS`): a case sets every precondition it turns on (`selftest/dispatch.sh` header).
- Last plan of `halt-and-hold`? `git grep -l 'requirement: halt-and-hold' origin/main -- docs/plans` with this plan excluded prints nothing = this pull request also deletes `docs/product/halt-and-hold.md` (`.agents/docs/product/README.md`, Satisfied).

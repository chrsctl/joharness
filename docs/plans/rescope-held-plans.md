---
plan: rescope-held-plans
urgency: normal
agent: opus
effort: high
needs: none
requirement: orchestrated-mode
scope: joharness.sh, .agents/harness/selftest/dispatch.sh, .claude/commands/manage.md, .claude/commands/orchestrate.md, .agents/docs/orchestrated.md, .agents/docs/plans/README.md
---

## Goal

Requester, 2026-09-10: *"We have a lot of work in gx, why doesn't it show
up for the orchestrator; do we need to decompose work?"* and, told the
cause, *"Can we implement a research decomposition as a mode for
managers."* Start with joharness.

The cause is not decomposition. `./joharness.sh dispatch` in `chrsctl/gx`
at `6181a43` (2026-09-10) read 58 plans, 38 of them `HOLD` behind ONE
branch, `claude/crm-workflow-gate`, and printed `DRAINED — nothing free`
with `2 of 4` slots free. Ten of the 38 were held on
`tools/criteria/index.py`, ten on `docs/adr`, four on `docs/phases` —
registries every plan in that repo appends to, declared exclusive. Run 1
recorded the same state (`.agents/docs/orchestrated.md`, Runs: *"passes 11
through 17 spawned nothing while 2 to 3 slots sat idle"*) and filed nothing.
The mechanism exists — `shared:` in `scope:` — and 17 of 58 plans use it;
`wave_split_hit` is asymmetric on purpose, so the 14 that marked the
criteria index shared are held anyway by the holder's exclusive claim.

Simulated on the 38 with the hook's own overlap rules (registries and the
`docs/adr` / `docs/phases` subtrees marked `shared:` on both sides): 21
released, 17 still held on code (`platform/appform/ai/workflows.py` 8,
`meta/ddl.py` 5, `server.py` 2). The 17 are right to wait.

Two changes. `dispatch` stops calling that state DRAINED — the word means
*no work*, and an orchestrator that reads it exits or idles. And a manager
gets a fourth item kind, `rescope`, that corrects the declarations and
nothing else, spawned by the orchestrator on the new verdict, bounded to
one per holder-set per run, beyond the cap like a reporter.

## Scope

- `joharness.sh:cmd_dispatch` — when `n_slots > 0`, `n_free = 0`,
  `n_wait = 0`, `n_hold > 0`: verdict `OVERLAP-BOUND — <slots> slot(s)
  free, <held> plan(s) held behind <n> branch(es): spawn ONE rescope
  manager (agent: sonnet) on key <key>, unless one is in flight or the
  ledger says rescoped=<key>`. Before the verdict, a `rescope   :` block:
  the key (holder plan stems, sorted, joined with `+`), every held path
  with its count descending, and the rescope branch in flight, if any —
  branch, status, push age, session, next — read the way a manager row is.
  `dispatch_rescope_branches`: unmerged remote refs whose own workstream
  file (changed against the merge base, never inherited) reads
  `workstream: rescope-<key>` and `plan: none`. Nothing else in the
  verdict order moves: PAUSED, NOT DRAINED (free, or waiting) stay ahead
  of it; DRAINED keeps `0 slots` and `0 held`.
- `.claude/commands/manage.md` — 0.3 gains `rescope <key>`: claim on
  `docs/handover/rescope-<key>.md` (`plan: none`, `workstream:
  rescope-<key>`); for every held plan the prompt names AND every holder,
  rewrite `scope:` and nothing below the frontmatter — a path the plan's
  own Scope section says it appends to or registers in becomes `shared:`,
  a directory the Scope section narrows to one file becomes that file, a
  path the plan edits in place stays; the holder is marked too, because
  one side's marking voids nothing. Never split a plan, never mark an
  in-place edit; what needs splitting is one line in the pull request body
  for the human. Nothing changed = `status: done`, `next:` says so, no
  pull request, exit. Section 4 gains one line for every manager: a
  modify/delete conflict on your own retired plan file when `main` comes
  in = keep the delete.
- `.claude/commands/orchestrate.md` — step 3: on `OVERLAP-BOUND`, with the
  `rescope` block saying `in flight: none` and no `rescoped=<key>` in the
  ledger, `create_session` title `rescope: <key>`, model = sonnet by the
  Lineup, prompt `/manage rescope <key>` plus the `rescope` block verbatim
  plus the same three lines every manager gets. Ledger `rescope-<key>@new`
  and `rescoped=<key>`; the health rows read it as a manager. Holds no
  slot. The Never list: never spawn a second on one key in one run.
- `.agents/docs/orchestrated.md` — Roles: a `rescope` row; What the mode
  changes: the verdict; Concurrency: the rule and its bound; Runs: the run 1
  paragraph points here.
- `.agents/docs/plans/README.md` — "Some files every plan touches": one
  sentence naming what orchestrated mode does about an unmarked one.
- `.agents/harness/selftest/dispatch.sh` — every free plan held with a slot
  free = `OVERLAP-BOUND`, the key, the paths with counts; a rescope branch
  in flight is listed and the verdict says so; `status: done` on it reads
  as nothing to rescope; held with 0 slots stays DRAINED; a WAIT row still
  outranks it; a hold released behind a BLOCKED holder is free, not bound.

## Out of scope

- The sweep of `chrsctl/gx`'s 58 plans. The first rescope manager there
  does it, or a supervised session after the sync — the requester said
  joharness first.
- A lint on bare directories in `scope:`. Which directory is a registry is
  the consumer's knowledge; the rescope manager reads the plan's own Scope
  section, and the wave partition already names the collision.
- Splitting plans. Product judgement; the rescope kind reports it.
- Changing `wave_split_hit`'s asymmetry (PR213 r6 fixed the other
  direction on purpose).
- A slot for the rescope manager. Beyond the cap, like a reporter; bounded
  by the ledger instead.

## Acceptance

- `./joharness.sh ci` — pass.
- `./joharness.sh verify` — 0 failed, count read off the run.
- `.agents/harness/selftest.sh` — the six dispatch cases above green; with
  the verdict branch commented out, the first reds (`mutate`, if the runner
  offers it; else by hand, recorded in the workstream file).
- SHIPS: `joharness.sh` and `.claude/commands/*` sync to every consumer.
  In `chrsctl/gx` after sync, `./joharness.sh dispatch` at a head where
  every free plan is held prints `OVERLAP-BOUND` and the `rescope` block;
  the number of plans it names held on `tools/criteria/index.py` matches
  `grep -l '^scope:.*[^:]tools/criteria/index.py' docs/plans/*.md | wc -l`
  minus the ones marked shared on both sides.

## Where to look

- `joharness.sh:cmd_dispatch` — the verdict ladder and `holdmap`, which
  already carries `<stem>\t<holder> on <path> (claimed on <branch>)` per
  held plan: the key and the path counts are read from it, not recomputed.
- `joharness.sh:dispatch_retired_edges` — the ref walk the rescope scan
  copies: merged refs dropped, no merge base counted not skipped, a
  workstream file read at the branch, never inherited from the base.
- `.agents/harness/queue-context.sh:wave_split_hit` — the asymmetry, and
  why the holder's plan is edited too.
- `.agents/harness/queue-context.sh:scope_lines` — the one reader of
  `scope:`; the rescope manager's edits must survive it unchanged.
- `.claude/commands/orchestrate.md` step 3 and step 4 — where the
  reporter's `reported=` ledger field is written; `rescoped=` follows it.
- `.agents/harness/selftest/dispatch.sh` — the HOLD cases (`gamma`,
  `sharer`, `held`, `iotapeer`, `zpeer`) are the fixtures the new cases
  extend.

## Traps

- A verdict the orchestrator branches on is one line; a degradation
  printed under it is stepped over (verifier round 2, r4 on `dispatch`).
  `OVERLAP-BOUND` is on the verdict line, not a tail under DRAINED.
- Never `for x in $items` over paths; newline list, `while read` (PR233 r1).
- `rescoped=` is a ledger field the orchestrator keeps; never take its
  value from a file (orchestrate.md step 4).
- Protocol text in scope: this plan is SUPERVISED ONLY and says so here.
- No number written that a command did not produce; the 38, 21, 17 above
  carry their command and date.

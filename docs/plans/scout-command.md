---
plan: scout-command
urgency: normal
agent: opus
effort: high
needs: fable-tier, scout-cycle
requirement: scout-role
scope: .claude/commands/scout.md, .claude/commands/orchestrate.md, .claude/commands/start.md, .agents/docs/orchestrated.md, .agents/docs/unsupervised.md
---

## Goal

`docs/product/scout-role.md`, bullets three to six: the role itself. A
scout is spawned when `scout : DUE` prints, reads evidence, writes ONE
`docs/product/<proposal>.md` as a pull request titled `proposal: <stem>`,
and exits. The human merges or closes; `JOHARNESS_SCOUT_AUTOMERGE=on` is
the one exception. This plan writes the command file that IS the role and
wires the orchestrator and `/start` to spawn or route to it. Last plan of
the requirement: its pull request deletes `docs/product/scout-role.md`.

Why the bounds are the whole file: a scout is the first role allowed to
write a file nothing asked for, and the harness's standing rule is that
nothing is invented. The requirement reconciles the two by making the
proposal a draft the human authors by merging. Every line of the command
must keep that true — a scout that writes a plan, a research node, or
merges without the key has invented work, and that is a red run, not a
judgement call.

## Scope

- `.claude/commands/scout.md`, frontmatter `description: Scout role —
  research new capacities and propose them as requirement pull requests;
  a human merges unless the conf says otherwise`. Sections, in the
  janitor file's order:
  - **0. Preconditions** — unattended = `authority` VERIFIABLE; `./joharness.sh
    scout` says `due` and no `IN FLIGHT`; verdict was DRAINED (the
    command prints it); `off` = stop.
  - **1. Claim** — cut from `main`, `docs/handover/scout-<UTC date>.md`,
    `workstream: scout-<UTC date>`, `plan: none`, `agent: fable`, push NOW.
  - **2. Read** — the evidence list, verbatim from the requirement:
    `./joharness.sh upstream`, `scorecard`, `review` churn, feedback
    graduations (`./joharness.sh feedback`), open issues on the canonical,
    the control plane's cost reader (`get_session`: `usage.cost_usd`,
    `usage.cache_read_tokens`, `context_usage.used_tokens`), and a dated
    read of Anthropic release notes / the Models API. Each read is one
    line in the workstream file's `## Decisions` with its date.
  - **3. Propose** — ONE `docs/product/<stem>.md` from the requirement
    TEMPLATE, plus two sections the template lacks: `## Evidence` (every
    number with the command and the date that produced it) and `## Cost`
    (the saving or spend, counted the same way). No evidence = no
    proposal: exit with `NOTHING TO PROPOSE` and no branch, which is
    success. One proposal per pass, the one with the largest counted
    number.
  - **4. Pull request** — title `proposal: <stem>`; body = the Goal
    paragraph and the Cost line; retire commit deletes the scout's own
    workstream file BEFORE the PR opens (step 7's rule).
  - **5. Merge** — `JOHARNESS_SCOUT_AUTOMERGE` as `./joharness.sh scout`
    resolved it: `off` = exit, the PR is the human's, say so in the
    report. `on` = step 7's own gate (`./joharness.sh finish` green, checks
    green, 0 behind) then merge-commit; nothing else changes.
  - **Never** — write under `docs/plans/` or `docs/research/`; edit a
    protocol path (`./joharness.sh protocol-paths`); spawn; open a second
    pull request; merge with the key off; propose without a citation.
- `.claude/commands/orchestrate.md` — spawn rule beside the janitor's: tail
  line `scout DUE` = ONE scout, tier fable, ONLY under DRAINED, ONLY when
  the `scout :` block says none is in flight and the ledger has no
  `scouted=` for this run. `title` = `scout: <UTC date>`, `model` = the
  Lineup's fable, `prompt` = `/scout` plus the three lines every manager
  gets. Ledger `scouted=<stamp>`. Health rows read its branch like any
  manager's. `NOTHING TO PROPOSE` with no branch = success, not a stall.
  Its merged or closed PR is the human's; the orchestrator never nudges a
  scout waiting on one.
- `.claude/commands/start.md` — supervised / unsupervised routing: `drain`
  printed a `scout :` block = this session's item is `/scout`.
- `.agents/docs/orchestrated.md` — Roles table row: `scout | fable; the
  judgement is which counted number is largest, never what to build | a
  session, spawned on the scout DUE tail line, only at DRAINED | nothing |
  one proposal pull request | the human merges or closes it, or NOTHING TO
  PROPOSE`. "What each role reads" row: reads `./joharness.sh scout` and
  the evidence it lists; never opens a plan, the queue order, product
  code. Bounds section: one paragraph on why a proposal is not invented
  work (the merge is the authorship) and what the automerge key changes.
- `.agents/docs/unsupervised.md` — the no-inventing bound gains one
  sentence pointing at that paragraph: a proposal pull request is the one
  thing a session may write that no node asked for, and it enters the
  queue only through a human's merge or a human's conf line.
- Retire: delete `docs/product/scout-role.md` in the last commit before
  the PR opens (last plan of the requirement).

## Out of scope

- Running the first scout. That is the NEXT session's — queue work the
  moment `scout : DUE` prints.
- The three candidates in the requirement's Evidence section. They are the
  first scout's to count, not this plan's to schedule — copying them into
  `docs/plans/` is exactly the invention the role forbids.
- Any change to `joharness.sh` — `scout-cycle` owns it.
- A `/scout` under supervised that merges: the key, not the mode, decides.

## Acceptance

- `./joharness.sh ci` — `ci: pass` (glossary scan covers
  `.claude/commands/`; `model tier` is banned, write `agent tier`).
- `grep -c 'scout' .claude/commands/orchestrate.md` — at least 4 (the
  spawn rule, the ledger key, the title, the stall carve-out).
- `grep -n 'scout' .claude/commands/start.md` — one routing line.
- `./joharness.sh drain` on this repo after merge, with
  `JOHARNESS_SCOUT_HOURS=1` and no scout history — prints the `scout :`
  block only if the verdict is DRAINED; on this repo's queue today that is
  `due, suppressed — not DRAINED`.
- `test ! -f docs/product/scout-role.md` on the PR head — the requirement
  is retired with its last plan.
- SHIPS: `.claude/commands/` and `.agents/docs/` sync to consumers; a
  consumer's `/start` reaches the role at its next sync.

## Where to look

- `.claude/commands/janitor.md` — the section order and the voice; §0 and
  §1 copy almost verbatim.
- `.claude/commands/orchestrate.md`, the `janitor DUE` bullet — the spawn
  rule to mirror, ledger key and all.
- `.agents/docs/orchestrated.md` Roles and "What each role reads" — the row
  shapes.
- `.agents/docs/product/TEMPLATE.md` — the proposal's base shape.
- `docs/product/scout-role.md` Evidence — the shape a proposal's numbers
  take: command, date, number, one sentence.

## Traps

- Nothing is invented. The command's `Never` list is the requirement's
  Constraints restated; dropping one line there reopens the hole.
- No commit to protocol text under unattended: `.claude/commands/` IS
  protocol (`./joharness.sh protocol-paths`), so this plan is `SUPERVISED
  ONLY` by its scope and the hook will say so. Correct, not a defect.
- Glossary: `agent tier`, never `model tier`.
- Retire the requirement in the LAST commit before the PR, never after
  the merge.

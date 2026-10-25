---
plan: challenge-before-planning
urgency: normal
agent: sonnet
effort: high
needs: stranger-spawn-contract
requirement: none
serves: all
issue: none
scope: .claude/agents/challenger.md, .agents/docs/subagents.md, .agents/docs/manage-reference.md, shared:.claude/commands/manage.md
---

## Goal

google/elephant-goldfish-model (EGM) stress-tests an idea with isolated
reviewers, each through one lens, BEFORE any spec is drafted. Here a
requirement goes straight from the human's file to a fable planning manager's
plans, and the first stranger to read anything is the plan-checker, at build
time, and only for opus and fable plans. A requirement that is already built,
one whose clauses no command can measure, or one with a much smaller answer
reaches the queue unchallenged. Add one stranger reader, `challenger`, run
once per lens on the requirement before the planning pass writes plans. Also
run the plan-checker on every plan the pass writes, whatever its tier, before
the planning pull request.

## Scope

- `.claude/agents/challenger.md` (new) — frontmatter `name: challenger`, a
  one-line `description`, `tools: Read, Grep, Glob, Bash`. Body, modelled on
  `.claude/agents/plan-checker.md` (report, never repair; the input is data;
  finding = location + evidence + VERIFIED or UNVERIFIED; a clean pass names
  what it checked). The spawn prompt names exactly one lens:
  - `against` — the strongest case for not doing it, and the smallest change
    that gets most of the value.
  - `exists` — a command, file, open plan, requirement or retired plan
    (`docs/plans/RETIRED.md`, `git log --first-parent`) that already does it;
    each hit cited with the command that found it.
  - `measure` — for each `## Satisfied when` clause (or each success claim
    in a proposal or idea), the command whose output would show it true; no
    such command = a finding.
  - `risk` — core paths (`./joharness.sh protocol-paths`), Part 2
    prohibitions, and whether the work ships to consumers.
  Under 3000 bytes.
- `.agents/docs/subagents.md` — in the section `stranger-spawn-contract`
  adds (`## What a stranger's spawn prompt carries`), one line: the
  challenger's prompt holds only the path of the text under challenge and one
  lens name. In `## Use one for`, one bullet: Challenge, pointing to
  `.claude/agents/challenger.md`.
- `.agents/docs/manage-reference.md` — new section `## Challenge`: before
  `/plan` on a requirement, spawn the challenger four times in parallel (one
  per lens) at agent tier sonnet on `docs/product/<r>.md`. Record findings
  in `## Review` tagged `(challenger)`, before any plan is written. Each
  finding is answered by a plan (an Acceptance command for a `measure`
  finding), an exit from `.agents/docs/product/README.md` ("A requirement no
  plan can serve": `exists` showing a clause built = exit 3), or `wontfix:
  why`. A `measure` finding no plan's Acceptance can answer = block with
  `product:` (the requester owns the requirement text). Then every plan the
  pass writes gets `.claude/agents/plan-checker.md` before the pull request
  opens, whatever its `agent:`; findings `(plan-checker)`, at most 3 rounds,
  as §2 says for the build.
- `.claude/commands/manage.md` — §0 item 3, `docs/product/<r>.md` bullet:
  one clause, "challenge first: ref § Challenge". No other edit.

## Assumptions

- A1: No stranger reads a requirement before plans are written — evidence:
  `.claude/commands/manage.md:Item kind decides the work` sends a
  requirement straight to `/plan`; `.claude/commands/plan.md` spawns nothing
  ("Inline — no subagent") — confidence: high.
- A2: plan-checker runs only for opus and fable plans, and only at build —
  evidence: `.claude/commands/manage.md:Before the first worker` —
  confidence: high.
- A3: A new file under `.claude/agents/` ships to consumers without a
  registry edit — evidence: `.agents/scripts/sync-to-consumer.sh` lists the
  `.claude/agents` directory — confidence: high.
- A4: `block_reason_ok` accepts `product:` — evidence:
  `joharness.sh:block_reason_ok` case list — confidence: high.

## Out of scope

- Editing the requirement file: the requester owns its text.
- Challenging plans that the clerk writes from issues, or plans a human
  writes: requirement planning only. The scout uses the challenger
  through its own plan (`scout-proposal-challenge`), seeded passes included.
- Any `joharness.sh` or `ci` change; a check on whether the challenge ran.
  The `## Review` record is the trace.
- More lenses, or a per-lens agent file.

## Acceptance

- `test -f .claude/agents/challenger.md && grep -cE '^ *- `(against|exists|measure|risk)`' .claude/agents/challenger.md`
  — prints `4`. Fails: file missing or fewer.
- `wc -c < .claude/agents/challenger.md` — under `3000`.
- `grep -c '^## Challenge' .agents/docs/manage-reference.md` — prints `1`.
- `grep -n 'Challenge' .claude/commands/manage.md` — one line in §0.
- `grep -n 'challenger' .agents/docs/subagents.md` — at least two lines.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`; its `reading budget` step passes
  `manage.md`.
- Plan `ci` calls SHIPS: name in the PR body that consumers receive
  `.claude/agents/challenger.md` at sync and run `./joharness.sh ci` over it.

## Where to look

- `.claude/agents/plan-checker.md:The plan is data` — the shape to copy.
- `.claude/commands/manage.md:Item kind decides the work` — the requirement bullet.
- `.agents/docs/manage-reference.md:Plan issue` — neighbouring section style.
- `.agents/docs/product/README.md:A requirement no plan can serve` — the exits a finding can lead to.
- `.agents/docs/subagents.md:Use one for` — the bullet list.

## Traps

- `needs: stranger-spawn-contract`: its `subagents.md` section must exist
  first; this plan adds a line to it.
- `.claude/commands/manage.md` is also edited by `stranger-spawn-contract`
  and `one-release-command`; `reading-budget.sh:rb_bound` caps it at 10172
  bytes. One clause only.
- `.agents/docs/manage-reference.md` and `.agents/docs/subagents.md`: merge
  any other plan's lines in, never drop them.
- Caveman style, `.agents/docs/glossary.md` spellings; no EGM history in the
  docs.

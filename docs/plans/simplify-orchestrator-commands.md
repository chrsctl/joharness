---
plan: simplify-orchestrator-commands
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
issue: none
scope: .claude/commands/orchestrate.md, .claude/commands/keeper.md, .claude/commands/start.md, .agents/docs/orchestrate-reference.md
---

## Goal

The user asked to simplify the protocol. The orchestrator and keeper role
files are the largest role text a session loads (orchestrate.md 366 lines,
orchestrate-reference.md 401, keeper.md 96). They repeat rules, carry
dated history the Status quo rule bans (`.agents/docs/caveman.md`), hold
dead tokens, and define LIVE orchestrator twice, differently. Cut them to
one statement per rule with no change to the behaviour they describe.

## Scope

- `.claude/commands/orchestrate.md`:
  - Delete history: the "99,920 characters, 2026-10-13" aside and the
    "(measured: one self-attach worked, one was denied at `git clone`)" aside.
  - Fix dead token: the line keyed on "`SHALLOW CLONE` on the verdict".
    dispatch prints `DEGRADED — shallow clone` (`joharness.sh:cmd_dispatch`),
    so match that text instead.
  - Fix the dangling "say which once:" whose list moved to the reference.
    Point to the reference section instead.
  - Collapse the repeated "(glossary, role title: the bare spelling matches
    too)" notes into one sentence near the top of the file.
  - Move to `orchestrate-reference.md`: the `status_bucket` field table and
    ignored-fields paragraph, the spawn-prompt detail, the ledger grammar and
    most of § Report. Leave a one-line pointer for each.
  - Delete the second "never act on a lead" statement.
  - Resolve the routing contradiction with start.md: the title-overrides-
    prompt rule stays here, and start.md says it.
- `.claude/commands/keeper.md`:
  - Delete "(read 2026-10-16)" and "(read 2026-10-23)".
  - Replace its own LIVE-orchestrator definition with a pointer to the
    one in orchestrate-reference.md.
  - Collapse the repeated role-title notes.
- `.claude/commands/start.md`: state the full routing table once,
  including the session-title rule from orchestrate.md. Every other file
  points here.
- `.agents/docs/orchestrate-reference.md`:
  - Delete the "older spec" and "A Routine made to an older spec…"
    migration shims, and the `/orchestrate keeper` prompt form that nothing
    parses.
  - Cut § Resume to a pointer at § Relay.
  - Define "BLOCKED BEFORE CLAIM", "UNCLAIMED" and "STILLBORN" in prose
    once, outside table cells.
  - Write `create_session` parameters once (including `clone_depth: 5000`,
    which the REGISTER spawn omits today). Other mentions point here.
  - Make the LIVE-orchestrator definition the single one. Before writing,
    read `cmd_keeper` in `joharness.sh` and state what the code counts.
  - Cut the comment-counting rules (scout gate, footer, write access) to a
    pointer at `.claude/commands/clerk.md` THE SCOUT GATE.

## Assumptions

- A1: Every line and quote above is from origin/main 860a3f9c. Line numbers drift, so find each by its quoted text — evidence: `git grep -n 'SHALLOW CLONE\|99,920\|read 2026-10' .claude/commands` — confidence: high.
- A2: dispatch's shallow-clone verdict text is `shallow clone` — evidence: `grep -n 'shallow clone' joharness.sh` — confidence: high.
- A3: No selftest greps phrases out of these four files — evidence: `grep -rln 'orchestrate.md\|keeper.md\|orchestrate-reference' .agents/harness/selftest` — confidence: medium. Run it, and keep any phrase a hit asserts.

## Out of scope

- `joharness.sh` and every script: this plan is prose only. If a prose fix
  needs a code change (for example a `role --noop` flag), record it as a
  `## Review` finding with `wontfix: code change, separate plan`.
- Rewording rules that are neither duplicated nor historical. This plan
  removes text. It does not restyle.
- Any other role command or doc: sibling plans own those (Traps).

## Acceptance

- `git grep -nE '99,920|read 2026-10|older spec|SHALLOW CLONE' .claude/commands .agents/docs/orchestrate-reference.md`: no output.
- `cat .claude/commands/orchestrate.md .claude/commands/keeper.md .claude/commands/start.md .agents/docs/orchestrate-reference.md | wc -l`: at most 780 (889 today).
- `git grep -c 'role title' .claude/commands/orchestrate.md`: at most 1.
- `./joharness.sh ci`: `ci: pass`.
- Consumer-side check: the same `./joharness.sh ci` runs in every consumer after sync and lints these files (glossary, anchors).
- `./joharness.sh verify`: `0 failed`.
- The pull request body lists every moved section as `from` and `to`, so a
  reviewer can check that nothing was dropped.

## Where to look

- `.claude/commands/orchestrate.md:Report`: the section to move.
- `.agents/docs/orchestrate-reference.md:Relay`: the section § Resume restates.
- `joharness.sh:cmd_keeper`: the code's LIVE definition.
- `joharness.sh:cmd_dispatch`: the shallow-clone verdict text.
- `.agents/docs/caveman.md:Status quo`: the rule that bans the history lines.

## Traps

- Do not change behaviour. Each removed sentence is either stated elsewhere
  (name where in the pull request) or is history.
- `ci` lint_glossary bans `handover file`, `model tier`, `env layer`,
  `rescope manager` and `bare role title`. Reworded text must avoid them.
- Sibling plans: simplify-role-commands owns clerk.md, which is the home of
  the scout gate. This plan only points there and does not edit it.

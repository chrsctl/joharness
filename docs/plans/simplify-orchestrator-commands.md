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
    ignored-fields paragraph, the unpinned spawn-prompt detail and the
    unpinned part of § Report. Leave a one-line pointer for each. The ledger
    grammar, the lead line and the Report heading stay: the selftest pins
    them in orchestrate.md.
  - Delete the health table's "never act on it": the Report's pinned "You
    relay a lead. You never act on one." is the statement.
  - Routing: keep the pinned sentence "Role comes from the prompt, the
    session-start banner's rule". The title-overrides-prompt rule stays
    here; start.md names it in one line pointing here.
- `.claude/commands/keeper.md`:
  - Delete "(read 2026-10-16)" and "(read 2026-10-23)".
  - Its LIVE-orchestrator clauses are the reference's definition read on
    the sessions the keeper can name (it has no `list_sessions`). Say so in
    one line. Keep every phrase the selftest pins.
  - Role-title notes: all three are pinned; none goes.
- `.claude/commands/start.md`: the one full routing table, plus one line
  naming the session-title rule in orchestrate.md. AGENTS.md step 2 keeps
  its short routing line (plan simplify-role-commands leaves it).
- `.agents/docs/orchestrate-reference.md`:
  - Keep the "older spec" compatibility and the `/orchestrate keeper` prompt
    form: they decide which Routines get REPLACE, so they are behaviour.
  - Cut § Resume's restated § Relay mechanics to a pointer. Its `next:`
    texts and commit messages stay (`joharness.sh` matches `Resume: the fix
    for #<n> merged`).
  - Define "BLOCKED BEFORE CLAIM", "UNCLAIMED" and "STILLBORN" in prose
    once, outside table cells.
  - Write the shared `create_session` parameters (`source_url`,
    `clone_depth`) once. Other mentions point here; per-role `model`,
    `title` and `prompt` stay where they are pinned. `keeper.md` keeps its
    own copy: the keeper reads no reference.
    REGISTER omits `clone_depth: 5000` today. Record that as a `## Review`
    finding (`wontfix: behaviour change, separate plan`). Do not add it.
  - Make the LIVE-orchestrator definition the single one (no code counts
    it: there is no `cmd_keeper`).
  - Cut the SCOUT COMMENT definition (footer, write access) to a pointer at
    `.claude/commands/clerk.md` THE SCOUT GATE. "A scout issue needs the
    scout" and its (i) to (iii) stay: pinned, and cited by scout.md.

## Assumptions

- A1: Every line and quote above is from origin/main 860a3f9c. Line numbers drift, so find each by its quoted text — evidence: `git grep -n 'SHALLOW CLONE\|99,920\|read 2026-10' .claude/commands` — confidence: high.
- A2: dispatch's shallow-clone verdict text is `shallow clone` — evidence: `grep -n 'shallow clone' joharness.sh` — confidence: high.
- A3: `selftest/orchestrated.sh` pins dozens of phrases in all four files, including three "role title" guards in orchestrate.md and the `/orchestrate keeper` sentence — evidence: `grep -n 'orchestrate.md\|keeper.md\|orchestrate-reference' .agents/harness/selftest/orchestrated.sh` — confidence: high.

## Out of scope

- `joharness.sh` and every script: this plan is prose only. If a prose fix
  needs a code change (for example a `role --noop` flag), record it as a
  `## Review` finding with `wontfix: code change, separate plan`.
- Rewording rules that are neither duplicated nor historical. This plan
  removes text. It does not restyle.
- Any other role command or doc: sibling plans own those (Traps).

## Acceptance

- `git grep -nE '99,920|read 2026-10|SHALLOW CLONE|measured: one self-attach' .claude/commands .agents/docs/orchestrate-reference.md`: no output.
- `wc -l < .claude/commands/orchestrate.md`: at most 330 (366 today). The
  four-file total moves text, so it does not fall: at most 905 (889 today;
  the moved text gains section headings).
- `git grep -c 'role title' .claude/commands/orchestrate.md`: at most 3, the three the selftest pins.
- `./joharness.sh ci`: `ci: pass`.
- Consumer-side check: the same `./joharness.sh ci` runs in every consumer after sync and lints these files (glossary, anchors).
- `./joharness.sh verify`: `0 failed`.
- The pull request body lists every moved section as `from` and `to`, so a
  reviewer can check that nothing was dropped.

## Where to look

- `.claude/commands/orchestrate.md:Report`: the section to move.
- `.agents/docs/orchestrate-reference.md:Relay`: the section § Resume restates.
- `joharness.sh:cmd_dispatch`: the shallow-clone verdict text.
- `.agents/docs/caveman.md:Status quo`: the rule that bans the history lines.

## Traps

- `.agents/harness/selftest/orchestrated.sh` pins exact phrases in these files. Before cutting a sentence, `grep -n` it in that selftest. A pinned phrase stays byte-exact. Never edit the selftest to fit.
- Do not change behaviour. Each removed sentence is either stated elsewhere
  (name where in the pull request) or is history.
- `ci` lint_glossary bans `handover file`, `model tier`, `env layer`,
  `rescope manager` and `bare role title`. Reworded text must avoid them.
- Sibling plans: simplify-role-commands owns clerk.md, which is the home of
  the scout gate. This plan only points there and does not edit it.

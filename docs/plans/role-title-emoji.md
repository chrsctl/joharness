---
plan: role-title-emoji
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: shared:.claude/commands/orchestrate.md, shared:.claude/commands/keeper.md, shared:.agents/docs/orchestrate-reference.md, shared:.agents/docs/orchestrated.md, shared:.agents/docs/glossary.md, shared:joharness.sh, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

The requester wants every role's session title to open with an emoji, so
the session list reads at a glance on a phone. The platform already
prefixes `⚡` to a session a Routine fires (`⚡ heartbeat: chrsctl/joharness`,
measured 2026-10-23); the roles get their own. Retired and duplicate
orchestrators get theirs too.

## Scope

Decided (requester delegated the choice; single code points, no U+FE0F
variation selector, so an exact-string match never splits on an invisible
character):

| Title today | Title after |
| --- | --- |
| `keeper: <owner/repo>` | `🔑 keeper: <owner/repo>` |
| `orchestrator: <owner/repo>` | `🎼 orchestrator: <owner/repo>` |
| `orchestrator (retired): <owner/repo>` | `💤 orchestrator (retired): <owner/repo>` |
| `orchestrator (duplicate): <owner/repo>` | `👯 orchestrator (duplicate): <owner/repo>` |
| `manager: <stem>` | `🔨 manager: <stem>` |
| `surveyor: <key>` | `📐 surveyor: <key>` |
| `curator: <UTC date>` | `🧭 curator: <UTC date>` |
| `clerk: <UTC date>` | `📋 clerk: <UTC date>` |
| `conduct: <UTC date>` | `🧐 conduct: <UTC date>` |

- Every place that SETS a title (`create_session` `title`,
  `set_session_title`) writes the new spelling.
- Every place that MATCHES a title (one-orchestrator check, keeper title
  guard, `keeper-gone`, manager lookup by title, `@new` rebuild, REGISTER's
  keeper archive) accepts the new spelling AND the old one, so sessions
  live at merge keep counting. Spell the rule once (glossary row or one
  sentence in `orchestrated.md`) and point to it; do not repeat both
  spellings at every site.
- `joharness.sh` strings that print a title, and the selftest needles in
  `.agents/harness/selftest/orchestrated.sh` that pin them, follow.
- `.agents/docs/glossary.md`: one row naming the emoji per role.

## Out of scope

- The Routine name `heartbeat: <owner/repo>`: the platform's `⚡` covers
  it, and REGISTER/stale checks match it exactly. Unchanged.
- Comment prefixes (`clerk: <VERDICT>` on issues), issue titles (`scout: <proposal>`), pull
  request titles, branch names, commit messages.
- Renaming live sessions at merge. They age out; the old spelling matches.
- Any emoji in `.agents/harness/AGENTS.md` (every line loads every session).

## Acceptance

- `grep -rnE "title.{0,40}\`(keeper|orchestrator|manager|surveyor|curator|clerk|conduct): " .claude/commands .agents/docs`
  — every hit is a match site that also names the emoji spelling, or none.
- `./joharness.sh ci` — `ci: pass`; selftest pins at least the keeper,
  orchestrator, retired and manager emoji titles.
- `./joharness.sh verify` — 0 failed.
- Consumer side (this ships): in a consumer synced with the change,
  `./joharness.sh ci` — `ci: pass`, and its next `/orchestrate` titles
  itself `🎼 orchestrator: <owner/repo>`.

## Where to look

- `.claude/commands/orchestrate.md` — manager spawn `title`, lookup by title.
- `.claude/commands/keeper.md` — title guard, retired/back-to-live titles.
- `.agents/docs/orchestrate-reference.md` — "## 0. Start" step 3 and 5,
  REGISTER, periodic-roles table.
- `.agents/docs/orchestrated.md` — "Heartbeat: making the fleet long".
- `.agents/harness/selftest/orchestrated.sh` — needles quoting titles.
- `joharness.sh` — `printf` lines naming role titles.

## Traps

- Glossary: one spelling per contested term; `ci` fails on the others.
- Tree holds still while the verifier runs.
- A selftest needle changed without the text it pins changing is a red run.

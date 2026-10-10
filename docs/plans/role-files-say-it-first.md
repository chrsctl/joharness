---
plan: role-files-say-it-first
urgency: normal
agent: haiku
effort: low
needs: none
requirement: none
scope: shared:.claude/commands/orchestrate.md, shared:.claude/commands/manage.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

Two issues, one shape: a rule is right in the body of a role file but
missing or wrong where a session meets it first.
#303: `orchestrate.md`'s `description:` reads "exit at DRAINED" with no
qualifier. The skills listing shows that line to a session before it opens
any file. The body, the banner and the selftest all say "with nothing in
flight".
#304 (the `manage.md` half): "never wait for an answer in the session" is
in `manage.md` §3 prose, not in `manage.md`'s `## Never`, where a manager
looks for what it must not do. A consumer manager called `AskUserQuestion`
unattended and held its slot 10+ hours. The `.agents/harness/AGENTS.md`
half of #304 is `orchestrated-only-docs`' work, not this plan's.

## Scope

- `.claude/commands/orchestrate.md`, frontmatter line `description:`.
  Replace `exit at DRAINED` with `exit at DRAINED with nothing in flight`.
  Change no other word on the line.
- `.claude/commands/manage.md`, `## Never`: add this bullet, exactly, as
  the last bullet:

  ```
  - Wait in the session for a human's answer — any ask tool included
    (AskUserQuestion). A question is a push: `status: blocked`, `next:` =
    the question, push, exit (§3).
  ```
- `.agents/harness/selftest/orchestrated.sh`, beside the existing
  `orcmd`/`mgrmd` cases: two `expect`s.
  - `orchestrate.md`'s `description:` line (`grep -m1 '^description:'
    "$orcmd"`) contains `with nothing in flight`.
  - `manage.md`'s `## Never` section (`sed -n '/^## Never/,$p' "$mgrmd"`)
    contains `AskUserQuestion`.

## Out of scope

- A glossary row banning `exit at DRAINED`. The lint matches substrings,
  and the fixed phrase contains the banned one (#303 point 3). Any such row
  reds the fix itself.
- `.agents/harness/AGENTS.md` "Decide alone". `orchestrated-only-docs` owns
  that line (#304 fix 1).
- Any `dispatch` change. #304 fix 3 says nothing is owed there.
- Any other wording in either file.

## Acceptance

- `grep -m1 '^description:' .claude/commands/orchestrate.md` → ends with
  `exit at DRAINED with nothing in flight`.
- `sed -n '/^## Never/,$p' .claude/commands/manage.md | grep -c AskUserQuestion` → `1`.
- `bash .agents/harness/selftest.sh` → `0 failed`, and its `orchestrated` lines all pass. The topic files are "Not runnable alone" — never run one by itself
- Revert the two text edits only. Both new `expect`s FAIL. Restore them.
- `./joharness.sh ci` → `ci: pass`.
- SHIPS: `.claude/commands/` reaches consumers. The consumer check is the
  same two `grep` lines after the next sync.

## Where to look

- `.claude/commands/orchestrate.md` — the `description:` frontmatter field.
- `.claude/commands/orchestrate.md:## 4. Schedule the next pass, then end the turn` —
  the qualified rule (`DRAINED — nothing free, nothing in flight: exit`).
- `joharness.sh:cmd_session_start` — the banner text
  `exits at DRAINED with nothing in flight` (`grep -n` it). The wording to match.
- `.claude/commands/manage.md:## 3` — the bullet "Stuck on a decision only a
  human takes". The rule this repeats.
- `.agents/harness/selftest/orchestrated.sh` — `orcmd`, `mgrmd`, and the
  header comment: grep-check every needle against the real file.

## Traps

- `orchestrated-only`, `orchestrated-only-docs`, `issue-triager-role`,
  `plan-on-a-branch-visible` and `ledger-losses-named` edit
  `orchestrate.md` or `manage.md` too. All mark them `shared:`. Reconcile
  at step 7.
- The suite's own header: a needle typed from memory fails on the wrapped
  line. Grep the real file before you commit a needle.

---
plan: orchestrator-human-ordered-extras
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: 425
scope: shared:.claude/commands/orchestrate.md
---

## Goal

On 2026-10-12 the human answered a HUMAN issue mid-run and asked for it to
be planned now. orchestrate.md has no lawful path for "the human orders an
extra role session", so the orchestrator improvised three moves the rules
forbid or leave open:
- it messaged the finished clerk "Please run one more /clerk pass on #251";
- it spawned a second clerk whose prompt asserted its own authority ("The
  repository owner asked for this extra clerk pass…");
- it did not re-arm its 08:31 wake, which still said "clerk already ran
  this run — at most one per run" and named only the first clerk.

Give the human's order a defined path, and close the two improvisations.

## Scope

`.claude/commands/orchestrate.md` only:

- **§3 Spawn, role sessions:** add one bullet after the role table. A human's
  explicit order in this session to start one extra role session is
  allowed beyond "at most ONE of each per run". The prompt stays the command
  plus the standard lines, with nothing added. The ledger gets `extra=human`
  on that role's key. The human's words go in the report, quoted, never in
  the prompt. One extra per order.
- **§4 Schedule:** one rule. A spawn made outside a scheduled pass (in
  answer to the human) cancels the pending `send_later` (`delete_trigger`
  on its id) and re-arms it at once in §4's format, ledger included.
- **Never:** add "send a child session a message asking it to do more
  work. `send_message` to a child carries the health table's nudge text
  and nothing else." Keep caveman style, one line.

## Out of scope

- The clerk-clock bug that let the second clerk pass its precondition (#424).
- Relaying the human's answer onto the issue (#426).
- The standard-lines wording for role sessions (#427). This plan uses
  "the standard lines" by name only.
- Any change to `joharness.sh` or `dispatch` output.

## Acceptance

- `grep -n "extra=human" .claude/commands/orchestrate.md` — at least two
  hits (the §3 bullet and the §4 ledger format line).
- `grep -n "nudge text" .claude/commands/orchestrate.md` — the new Never line.
- `./joharness.sh ci` — `ci: pass` (the glossary lint included).
- `./joharness.sh verify` — 0 failed.

## Where to look

- `.claude/commands/orchestrate.md` §3, the role-session bullet "Role sessions, at most ONE of each per run".
- `.claude/commands/orchestrate.md` §4, the `send_later` format block and the ledger line.
- `.claude/commands/orchestrate.md` "Report, every pass", the existing "if the human orders it" carve-out for branch plans: match its shape.
- `.claude/commands/orchestrate.md` "Never".

## Traps

- orchestrate.md is protocol text, not a core path: editable. `joharness.conf`, `.claude/settings.json` and `.github` are not.
- The prompt routes and the repository authorises: the extra-spawn bullet must not add a line to the prompt.
- `#426`, `#427` and `#428` also edit orchestrate.md (different sections): reconcile expected at step 7.

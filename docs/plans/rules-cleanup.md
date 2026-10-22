---
plan: rules-cleanup
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: none
issue: none
scope: shared:.agents/harness/AGENTS.md, .claude/commands/orchestrate.md, .claude/commands/keeper.md, .claude/commands/start.md, shared:.agents/harness/selftest/orchestrated.sh, shared:.agents/docs/orchestrated.md, .agents/docs/history/consumer-repos.md, .agents/docs/history/handover.md, .claude/agents/verifier.md, .claude/commands/conduct.md, .agents/docs/handover/README.md, .agents/docs/consumer-repos.md, .agents/docs/agent-selection.md
---

## Goal

The harness review (session 2026-10-22) found the rule files disagree with
each other and with the code in places, load more than each session needs,
and carry history the repo's own style rule forbids
(`.agents/docs/caveman.md`, Status quo). Fix the contradictions, cut the
always-loaded text, and move history out of the docs.

## Scope

1. **Block reasons.** `.agents/harness/AGENTS.md` "Decide alone" says
   "Block ONLY for money, credentials, hardware, product direction, or a
   merge conflict". `.claude/commands/manage.md` and
   `joharness.sh:block_reason_ok` also accept `interface:`, `core path:`,
   `github:`, `stalled:`, `respawns:`. Make AGENTS.md name the same set by
   pointing to `block_reason_ok` (one copy), not by restating it.
2. **Loop step 2.** Cut `.agents/harness/AGENTS.md` step 2 "Pick" to the
   role routing only (prompt names `/manage <item>` → `manage.md`; else
   `/start`), dropping the hand-run picking order a manager must not follow.
   Keep any substring a selftest pins (`grep -rn` the selftests for each
   phrase you remove).
3. **Keeper split.** Move `## Keeper` from `.claude/commands/orchestrate.md`
   into a new `.claude/commands/keeper.md` with only what the keeper runs
   (Keeper plus the Tools it uses). `orchestrate.md` keeps a one-line
   pointer. Whatever schedules the keeper names `keeper.md`.
4. **Role routing.** `orchestrate.md` header (role from session TITLE) and
   `start.md` / the session-start banner (role from PROMPT) must name one
   rule. Keep the banner's rule; make `orchestrate.md` defer to it.
5. **History out of docs.** Remove dated incidents, issue numbers, session
   ids and measured-past narratives from `.agents/docs/orchestrated.md`,
   `.agents/docs/handover/README.md`, `.agents/docs/consumer-repos.md`,
   `.agents/docs/agent-selection.md`, `.claude/agents/verifier.md`,
   `.claude/commands/conduct.md`, `.claude/commands/orchestrate.md`. Keep
   the rule and the current number; the story stays in git log. Delete
   `.agents/docs/history/` and the `AGENTS.md` pointer to it, after
   checking no file still links into it (`grep -rn "docs/history"`).
- `.agents/harness/selftest/orchestrated.sh` — keep every existing pin
  green; add pins for `keeper.md` existing and `orchestrate.md` pointing to
  it.

## Out of scope

- `joharness.conf` dead knobs (`JOHARNESS_SCOUT_HOURS`,
  `JOHARNESS_SCOUT_AUTOMERGE`): core path, human PR.
- Changing any rule's meaning beyond making two copies agree.
- `.agents/docs/glossary.md` terms.

## Acceptance

- `./joharness.sh ci` — `ci: pass` (glossary and caveman lints included).
- `./joharness.sh verify` — `0 failed`.
- `wc -l .claude/commands/keeper.md` — under 150.
- `grep -rn "docs/history" .agents .claude AGENTS.md` — no output.
- `grep -nE "20[0-9]{2}-[0-9]{2}-[0-9]{2}" .agents/docs/orchestrated.md
  .claude/agents/verifier.md .claude/commands/conduct.md` — count in the
  PR body before and after; after is lower, every remaining hit justified
  in `## Review`.
- Plan `ci` calls SHIPS: every edited file reaches consumers at next sync.

## Where to look

- `.agents/harness/AGENTS.md` steps 2 and "Decide alone";
  `joharness.sh:block_reason_ok`; `.claude/commands/manage.md` block
  grammar.
- `.claude/commands/orchestrate.md` header, `## Tools`, `## Keeper`;
  `.claude/commands/start.md`; `joharness.sh:cmd_session_start` banner.
- `.agents/docs/caveman.md` Status quo.

## Traps

- Plans `checks-auto-local-fallback` and `human-review-simplify` also edit
  `.agents/harness/AGENTS.md`; three plans edit `selftest/orchestrated.sh`.
  Merge `origin/main` in before step 7 and keep every change.
- NEVER skip, disable or quarantine a test; existing pins keep their
  substrings.
- No core paths.
- Wide scope (12 entries): if the build runs long, split by numbered item
  into follow-up plans rather than leaving half done.

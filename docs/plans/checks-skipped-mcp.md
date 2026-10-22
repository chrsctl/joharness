---
plan: checks-skipped-mcp
urgency: normal
agent: sonnet
effort: high
needs: checks-auto-local-fallback
requirement: none
issue: none
scope: shared:.agents/harness/AGENTS.md, .claude/skills/steward/SKILL.md, shared:.agents/docs/consumer-repos.md, shared:.agents/harness/selftest/orchestrated.sh
---

## Goal

Plan `checks-auto-local-fallback` makes `finish` read the head's `lint`
check with `gh`, then unauthenticated `curl`. The owner reports (session
2026-10-22) that `gh auth` fails in their cloud sessions and the child
repos have only the GitHub MCP server, so a private child cannot be read
and stays in github mode. Every session already reads check runs through
the GitHub MCP server at step 7. This plan adds the protocol route: a
`skipped` `lint` on the head, read via MCP, sends the session to the local
gate for that one `finish` call. The repository variable then works as the
one switch in MCP-only environments too.

## Scope

- `.agents/harness/AGENTS.md` step 7, first bullet (the one starting
  "GitHub checks green on head") — add: "the head's latest `lint` check run
  concluded `skipped` (repository variable `JOHARNESS_CHECKS=local`) →
  run `JOHARNESS_CHECKS=local ./joharness.sh finish`; merge only on its
  `finish: pass (ci and verify ran here…)` line. A skipped check is never
  green." Keep the line count low (caveman style).
- `.claude/skills/steward/SKILL.md` "At merge" — the same rule, one line,
  pointing to AGENTS.md step 7 (one copy of the wording).
- `.agents/docs/consumer-repos.md` "Local checks" — one sentence: in an
  environment with only the GitHub MCP server, the session's step-7 read is
  what detects the skipped `lint`; `finish`'s own read covers `gh` and
  public repos.
- `.agents/harness/selftest/orchestrated.sh` (or the selftest that pins
  `.agents/harness/AGENTS.md` text; find it with `grep -rln "harness/AGENTS.md"
  .agents/harness/selftest`) — `expect` the substring `A skipped check is
  never green`. Red on `main` first.

## Out of scope

- Any `joharness.sh` change; `finish` already honours `JOHARNESS_CHECKS=local`
  from the environment for one command.
- Detecting billing-stopped runs (not started) — same exclusion as
  `checks-auto-local-fallback`.
- `.github/workflows/ci.yml` (core path).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `grep -c "A skipped check is never green" .agents/harness/AGENTS.md` — `1`.
- New `expect` case red without the AGENTS.md change; recorded in
  `## Review`.
- Plan `ci` calls SHIPS: AGENTS.md, steward skill and the selftest reach
  every consumer at its next sync.

## Where to look

- `.agents/harness/AGENTS.md` step 7 conditions.
- `.claude/skills/steward/SKILL.md` "At merge".
- `.agents/docs/consumer-repos.md` "Local checks".
- `joharness.sh:checks_local`, `checks_mode` — env read per command.
- The merged result of `checks-auto-local-fallback` (its `finish` pass line
  and messages), so the wording here matches.

## Traps

- `needs: checks-auto-local-fallback`: build after it merges; reword to its
  final messages.
- Plans `human-review-simplify` and `rules-cleanup` also edit
  `.agents/harness/AGENTS.md` (`shared:`); merge `origin/main` in.
- NEVER skip, disable or quarantine a test. No core paths.

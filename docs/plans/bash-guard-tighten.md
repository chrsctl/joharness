---
plan: bash-guard-tighten
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: .agents/harness/pretool-bash-guard.sh, .agents/harness/selftest/pretool-bash-guard.sh
---

## Goal

The PreToolUse bash guard (665 lines) denies some commands that do finish
and allows some that never do, and its heredoc stripper is quadratic (a
30,000-line heredoc takes 15 s, past the hook's 10 s timeout). Found by the
harness review, session 2026-10-22. Fix the bypass, the false positives and
the cost without widening what it blocks.

## Scope

- `timeout_re` check (around line 491) — a `timeout` counts only when it
  wraps the same simple command as the loop, matching the comment at
  495–498. `echo timeout 5; while :; do sleep 1; done` → denied.
- Loops with a finite input → allowed: `while read … done < file`,
  `cmd | while read …`, and `while [ "$(date +%s)" -lt "$deadline" ]`.
- `"sleep" 1` and `python -c '…time.sleep…'` inside a `while :` loop →
  treated like `sleep`.
- `strip_heredocs` (98–132) — linear in line count (one pass with a state
  variable, or `awk`).
- Selftest `selftest/pretool-bash-guard.sh` — one case per item; the
  20,000-line heredoc case finishes in under 2 s
  (`SECONDS` before/after). Each red on `main` first.

## Out of scope

- Removing the guard or changing `.claude/settings.json` (core path).
- New categories of blocked commands.
- The `pgrep -f` self-match rule (unchanged).

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- New selftest cases red without the change; recorded in `## Review`.
- Plan `ci` calls SHIPS: the guard and its selftest reach every consumer.

## Where to look

- `.agents/harness/pretool-bash-guard.sh`: `strip_heredocs`, `timeout_re`,
  the loop detector near 224–226 and 461.
- `.agents/harness/AGENTS.md` step 5 ("Background command must be able to
  finish (bound it); never `pgrep -f` a pattern your own command line
  carries") — the rule the guard enforces.

## Traps

- Hook must stay under its 10 s timeout and must fail open (a timeout lets
  the call through — never make it block on error).
- NEVER skip, disable or quarantine a test. No core paths.

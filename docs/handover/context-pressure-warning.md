---
workstream: context-pressure-warning
status: in-progress
branch: claude/context-pressure-warning-k7q2
pr: none
plan: context-pressure-warning
issue: none
session: https://claude.ai/code/session_01FmArP42iphRwRzXNj4HD4o
agent: opus
updated: 2026-10-23
next: ci + verify on the review fixes, then retire and open the PR (Refs #584)
---

## Goal

Warn a long-lived session before compaction takes its rules: once context
crosses a threshold, the next Edit/Write or Bash tool call carries one
injected line telling it to write the workstream file, commit and push.

## Decisions

- Re-scope, decided by the orchestrator on the human's delegation
  (2026-10-23). Every hook in `.claude/settings.json` runs straight from
  the working tree (`$CLAUDE_PROJECT_DIR/...`), so editing
  `pretool-feedback.sh` or `pretool-bash-guard.sh`, even a probe, changes
  the hook running on this session's own calls. That edit is what auto mode
  refused. New shape:
  1. `context-watch.sh` is a standalone hook script that prints its own
     PreToolUse `additionalContext` envelope. Nothing registers it while
     you build it, so it never runs on your own calls. Test it only through
     the selftest, by piping fixture payloads and transcripts to it.
  2. Never write, wrap or probe `pretool-feedback.sh`,
     `pretool-bash-guard.sh`, `handover-guard.sh` or the session-start
     path. The plan's edits to the two pretool hooks are dropped, and so is
     its bash-guard case. The knob rows in `joharness.sh` stay, since
     ordinary branches edit that file.
  3. The live-payload probe is dropped. `transcript_path` is a documented
     common hook input. A payload without it, or a transcript with no
     usage, prints nothing and exits 0, and a fixture case pins that.
  4. Registration is a core edit. Add one PreToolUse entry to
     `.claude/settings.json` (matcher `Edit|Write|NotebookEdit|Bash`,
     command `"$CLAUDE_PROJECT_DIR"/.agents/harness/context-watch.sh || exit 0`,
     a short `timeout`). It goes in a `human/context-pressure-warning` pull
     request labelled `human-review`, per manage.md §2. The human merges
     it, and that merge is when it first runs live.
  Rewrite the plan's Scope, Out of scope and Acceptance on this branch to
  match, and flag the re-scope in the pull request body.
- Design question, half settled. `usage` on assistant entries: CONFIRMED
  live, this session's transcript, 2026-10-23: `input_tokens`,
  `cache_creation_input_tokens`, `cache_read_input_tokens` present; nested
  `output_tokens_details:{...}` follows, so read each key alone, not
  `"usage":{[^}]*}`. `transcript_path` on PreToolUse: documented as a common
  hook input field, NOT captured live — the probe (tee stdin in the
  working-tree pretool-feedback.sh, then one Edit) was refused, see Blockers.
- Once per CLIMB, not once per session: a compaction keeps the session id
  and drops the context, so under the lowest live level the markers clear
  and the next climb warns again (verifier r4). Hysteresis is the gap
  between the post-compaction size and the warning level.
- Knobs are scope `session`: the hook reads the environment only, the way
  `./joharness.sh conf` prints them; a conf line is not read (r2, r3).
- Registration: human PR #584 (`human/context-pressure-warning`), command
  `bash <path> || exit 0` so a copy with no exec bit still runs.
- Built by this manager alone: one script and its topic share every
  decision, so no disjoint worker split existed.

## Rejected

- Editing the two registered pretool hooks to call the watcher: they run on
  the building session's own calls, so auto mode refuses the edit.

## Review

- r1: (verifier) context-watch.sh committed 100644; the registered path answers 126 and `|| exit 0` hides it; selftest ran it via bash so never saw it. (fixed)
- r2: (verifier) hook read a conf line that `conf` does not show for a session knob; values disagreed. (fixed)
- r3: (verifier) conf value with an inline comment fell back to the default where conf_get reads the number. (fixed)
- r4: (verifier) markers never cleared: a session warned before its first compaction only. (fixed)
- r5: (verifier) the non-number window case passed whether or not the fallback worked. (fixed)
- r6: (verifier) noclobber claim has no concurrent case. (wontfix: a race test is timing-dependent; set -C create-exclusive is the whole mechanism)
- r7: (verifier) handover still described the dropped bash-guard design. (fixed)
- r8: (verifier) registration had no Acceptance item; Scope opened with history. (fixed)

## Blockers

None.

## Where to look

- `.agents/harness/context-watch.sh` — the hook; markers and re-arm at the end.
- `.agents/harness/selftest/context-watch.sh` — the only way it is exercised.

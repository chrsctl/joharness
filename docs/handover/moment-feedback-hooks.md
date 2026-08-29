---
workstream: moment-feedback-hooks
status: in-progress
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: moment-feedback-hooks
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Fold the verifier round into ## Review, then retire and open the PR.
---

## Goal

Stage 4 of the feedback loop — Prevent, the only stage that changes an
outcome — rides on the model remembering to ask. A PreToolUse hook injects a
file's recorded findings the moment a tool is about to edit it.

## Decisions

- **The contract was verified before a line of the emitter, and the plan's
  central trap is real.** Official docs, checked this session: a PreToolUse
  hook reaches the model ONLY through
  `hookSpecificOutput.additionalContext`, with `hookEventName: "PreToolUse"`
  required beside it. Plain stdout goes to the debug log and is shown to
  nobody. Exit 2 is the one code that BLOCKS a tool call, so this hook can
  never produce it; stdout over 1 MB is truncated silently, and a truncated
  envelope parses as nothing.
- **The plan's figures were stale in the direction that matters.** Recounted
  2026-08-29: `./joharness.sh feedback joharness.sh` took 6774 / 6648 / 6846
  ms over three runs, not the plan's 3802 / 3942 / 3783 — history went from
  61 edges to 121. The cache is more load-bearing than the plan argues, not
  less.
- **The cache lives in `fb_collect`, gated on an env var the hook sets.** Off
  unless `JOHARNESS_FEEDBACK_CACHE` names a directory, so every command-line
  run walks history exactly as before — proven by diffing full and per-path
  output, cached against uncached: identical. Keyed by base tip and edge cap,
  NOT by HEAD: keying on HEAD would pay the walk again after every commit,
  which is most of the cost back.
- **A per-finding `grep` in `fb_report_path` was the rest of the cost.**
  Cached, a call still took 2808 ms, because the report forked a `grep -qxF`
  and two `cut`s per line of history — ~750 forks. One awk instead: **78 ms
  warm**, output byte-identical over 234 lines. Same shape as `review_prior`
  last plan, found the same way — by measuring once something started calling
  it often.
- **The injection is capped at 8 findings.** Uncapped, this repo's hottest
  file injects 32,518 bytes before the first edit of it. Capped: 3,055, with
  the exact count omitted and the command that shows the rest. "Hook output
  is paid on every fire" is the plan's own rule and 32KB is not caveman.

## Rejected

- (nothing yet)

## Review

(no round yet)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_feedback` — the report this serves; where the quiet
  shape lands.
- `joharness.sh:fb_collect` — the one history walk the cache answers.
- `.agents/harness/handover-guard.sh` — stdin handling and fail-open.

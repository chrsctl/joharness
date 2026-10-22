---
workstream: macos-portability
status: in-progress
branch: claude/macos-portability
pr: none
plan: macos-portability
issue: none
session: https://claude.ai/code/session_01NoHtepXiUMXAm5Lx5tEt6Z
agent: sonnet
updated: 2026-10-22
next: Run ./joharness.sh ci and verify; compare dispatch with origin/main (before file was /tmp, regenerate); verifier; retire; PR.
---

## Goal

Implement docs/plans/macos-portability.md.

## Review

- r1: (verifier) checks_gate/handover-context fetch now unbounded without timeout (wontfix: the plan orders it, copying role_fetch_all; skipping it was the bug)
- r2: (verifier) selftest checks.sh skip for no timeout is stale (fixed: case now runs unconditionally)
- r3: (verifier) lint false positive on a later awk -F'\t' and narrow -flags (fixed: regex scoped to the quoted sed script, any flags)
- r4: (verifier) lint skips selftest/*.sh and .agents/scripts (wontfix: plan scopes joharness.sh and .agents/harness/*.sh; selftests run on Linux CI)
- r5: (verifier) awk lint pinned to two names (wontfix: other -v values are single-line; checked)
- r6: (verifier) ENVIRON does not expand backslash escapes (no change: values are paths and stems)
- r7: dispatch before/after on Linux differs only in elapsed-time counters and this branch's own row (no change)
- r8: verify 2 passed 4 failed here, Docker Hub 429 on pulling alpine:3, no .agents/env file in the diff (wontfix: environmental; GitHub verify decides)

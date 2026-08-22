---
workstream: security-sweep
status: in-progress
branch: claude/security-sweep-setup-quote
pr: none
agent: sonnet
updated: 2026-08-23
next: none — two shell-safety hardenings landed with selftests; opening the PR
---

## Goal

A read-through of every shell script for the classic injection/traversal
classes turned up two spots where attacker-influenced text becomes code. Close
the two that have a clean, provable, cross-platform fix. The larger findings
(no checksum on downloaded binaries; bootstrap's purge lacks the symlink guard
sync already has) are named in the PR body as follow-ups, not fixed here.

## Decisions

- `env/k8s/setup.sh` writes `KUBECONFIG`/`DEVENV_CLUSTER_NAME` into a file a
  later shell sources. Switched the bare double-quoted `echo` to `printf %q`
  so a value carrying `"`, `` ` ``, or `$(...)` is escaped back to inert data.
- `valid_name` in `joharness.sh` used `printf %s | grep -qE`, which matches
  per line — a value with an embedded newline slipped past the anchors because
  one of its lines matched. Replaced with a whole-string `case` test.
- One PR, one concern (shell-safety). The download-integrity and bootstrap
  symlink findings are separate concerns and get their own PRs if Chris wants.

## Rejected

- Fixing the bootstrap symlink-ancestor purge in this PR. The guard asymmetry
  vs `sync-to-consumer.sh` is real, but the file-deletion path is Linux-only
  and could not be verified on the Windows test box — it needs a sandbox repro
  before shipping a fix, so it stays a named finding, not a guessed patch.

## Blockers

None.

## Where to look

- env/k8s/setup.sh — the env-file write.
- joharness.sh — valid_name.
- harness/selftest.sh — a case per fix (newline name rejected; hostile cluster
  name is inert when the written env file is sourced).

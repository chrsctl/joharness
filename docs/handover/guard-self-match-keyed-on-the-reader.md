---
workstream: guard-self-match-keyed-on-the-reader
status: in-progress
branch: guard-self-match-keyed-on-the-reader
pr: none
plan: guard-self-match-keyed-on-the-reader
issue: none
session: https://claude.ai/code/session_01BVQg9yj1cxLrFRYNqwgz3M
agent: opus
updated: 2026-10-10
next: Read selftest/ci results and verifier findings, record them in Review, fix, finish
---

## Goal

Guard denies a wait loop whose reader matches its own command line under
any reader (pgrep/pkill -f, ps | grep, /proc/*/cmdline) and any loop opener
(while, until, for, select) — plan guard-self-match-keyed-on-the-reader.

## Decisions

- No worker fan-out: one guard file plus its selftest, both shared and
  judgement-heavy regex; sequential by the plan's own scope.
- Exemption scope = any word of the reader's own simple command (pgrep) or
  the first grep stage's args (ps | grep, grep over /proc glob), quoted and
  opening `[c]`. Picking out "the pattern" positionally needs pgrep's
  option table; a bracket outside that command still exempts nothing.
- `for`/`select` reach judge() via tkw in reader B; judge returns after the
  self-match test for them, so the sleep test still precedes it.
- Acceptance rows run from a payload file (scratch runner): 24/24 on this
  guard, 15/24 wrong on origin/main's (2026-10-10).

## Rejected

- Patching via a shell heredoc: the live guard read the patch text as a
  loop and denied it. Edits go through files.

## Review

- r1: selftest structure check red — `bash .agents/harness/selftest.sh`
  (2026-10-10) printed 2497 passed, 1 failed: "this tree couples no harness
  file to a layer beyond the carve-out", naming the `docker ps` row and
  comment. Switched both to `podman ps`, the plan's other spelling of the
  same case. (fixed)

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:judge` — self-match branch.

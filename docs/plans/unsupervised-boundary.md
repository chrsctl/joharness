---
plan: unsupervised-boundary
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: unsupervised-mode
scope: docs/product/unsupervised-mode.md, joharness.sh, .agents/harness/AGENTS.md, .agents/harness/selftest.sh
---

## Goal

Issue #114. The boundary that keeps an unattended session from rewriting the
protocol governing it is spelled as ONE path prefix, `.agents/harness/`, in
three places — the requirement's Constraints, the session-start banner
(`joharness.sh`), and Loop step 2. `.claude/agents/verifier.md` is protocol
text now: step 5 requires spawning it and the merge gate leans on what it
returns. It sits outside that prefix, so all three statements miss it at
once.

Found by the verifier reviewing the diff that added it (PR #110, `r11`),
left unfixed there because it is a requirement edit and should not ride in
on a review-mechanism change.

## Scope

- `docs/product/unsupervised-mode.md`, Constraints — state the boundary by
  ROLE, with its current extent named: protocol text is off limits wherever
  it lives, and today that is `.agents/harness/` and `.claude/agents/`.
  Role alone is unenforceable; a path list alone goes stale the next time
  protocol text moves. Both, so a literal reader gets the rule and a
  checkable list.
- `joharness.sh`, the unsupervised banner — same two trees, same wording.
  One line, and it is read before the first prompt of every unattended
  session.
- `.agents/harness/AGENTS.md`, Loop step 2 — the same, in the caveman form
  that file uses.
- `.agents/harness/selftest.sh` — the banner names both trees; a fixture
  that names only one fails.

## Out of scope

- A mechanical gate that blocks the commit. The mode is advisory
  everywhere else in this repo and a session that ignores a stated boundary
  ignores a hook too. `ci` already reds on the specific deletion that
  motivated the issue (PR #110's assertion), which is the checkable half.
- The three limits the requester declined on 2026-08-24 (a work cap, a halt
  on red main, a ban on sessions spawning sessions). Naming two trees where
  one was named is not a fourth limit; adding one would be.
- Moving `.claude/agents/` under `.agents/`. It is where the client looks.

## Acceptance

- All three statements name both trees. `grep -rn '.claude/agents'
  docs/product/unsupervised-mode.md joharness.sh .agents/harness/AGENTS.md`
  returns a hit in each.
- `JOHARNESS_MODE=unsupervised ./joharness.sh session-start` prints a banner
  naming both. Paste it.
- `./.agents/harness/selftest.sh` — passes, count higher by the test added,
  and that test fails against the pre-change banner.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed. Required: touches `joharness.sh`.

## Where to look

- `docs/product/unsupervised-mode.md:44` — the Constraints bullet.
- `joharness.sh`, the `JOHARNESS_RUN_MODE = unsupervised` banner block.
- `.agents/harness/AGENTS.md`, step 2 "Boundary holds".
- Issue #114 — the sequence, and what already narrows it.

## Traps

- Three copies of one rule is why one path was missed in three places at
  once. Do not add a fourth copy; if a fourth reader needs it, point.
- The requirement is ratified. Widening a boundary the requester set is the
  kind of edit that gets recorded in the diff and named in the PR body, not
  slipped in.

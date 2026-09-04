---
workstream: license-notice
status: in-progress
branch: claude/licensing-matches-verify-qtamqe
pr: none
plan: license-notice
issue: none
session: https://claude.ai/code/session_01BgxrYUJru5VR12hRuPxkdV
agent: sonnet
updated: 2026-09-04
next: Build the plan's scope, then run ci and verify
---

## Goal

Human asked, verbatim: "Verify that alle pieces Matches licensing also when
distilled if not fix. And attribution." Check every distilled piece both
ways — text taken in from other projects, harness text handed out to
consumers — against the license each side requires, and fix what fails.

## Decisions

- Verified inbound (2026-09-04, upstream LICENSE files fetched from
  raw.githubusercontent.com): `.agents/docs/caveman.md` is a close
  derivative of `skills/caveman/SKILL.md` in JuliusBrussee/caveman — motto,
  pattern line, Not/Yes example and several rules verbatim. Upstream is MIT,
  Copyright (c) 2026 Julius Brussee; its LICENSE scope note puts only the
  engine directories under BSL, the skill is MIT. The file named the upstream
  and the word MIT and carried no copyright line: that fails MIT's one
  condition. Gas Town quotations in `prior-art.md` are short and attributed
  (MIT, Copyright (c) 2025 Steve Yegge). `graph.md` adapts ideas from
  codejunkie99/graph-engineering (MIT, Copyright (c) 2026 codejunkie99,
  default branch `master`), no text reproduced. Vale, Fowler, arXiv: short
  quotations with links, no license condition attaches.
- Verified outbound: `sync-to-consumer.sh` `FILES`/`DIRS` ship no license
  text at all. Fails the same condition for every consumer.
- Shipped notice lives at `.agents/LICENSE` + `.agents/NOTICE`, not root:
  root `LICENSE` in a consumer is that repo's own, and the previous plan
  rejected shipping there for exactly that reason. `.agents/` is the one
  path every consumer receives whole, and `.gitattributes` already pins it.
- Two files, not one: `LICENSE` stays byte-identical to root so a selftest
  can `cmp` them and drift is impossible; NOTICE holds prose (scope,
  third-party) that must not be pasted into MIT text.
- Third-party notices point at `LICENSE` beside them for the permission
  text rather than repeating the MIT body three times.

## Rejected

- Root `LICENSE` in `FILES`. Overwrites a consumer's license every sync.
- `.agents/harness/LICENSE`. Ships with no engine change, but names one
  subtree while the grant covers `joharness.sh`, `.claude/` and
  `.agents/docs/` too.
- Deleting a whole clone's root `LICENSE` in bootstrap. Consumer may keep
  MIT deliberately; a warning matches the README precedent.

## Review

(pending)

## Blockers

None.

## Where to look

- `.agents/NOTICE` — what the grant covers, and every upstream named.
- `.agents/scripts/sync-to-consumer.sh:FILES` — the two new entries.

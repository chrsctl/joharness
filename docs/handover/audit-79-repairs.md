---
workstream: audit-79-repairs
status: in-progress
branch: claude/audit-79-repairs
pr: none
plan: none
session: https://claude.ai/code/session_01UTCnacqdtMFMweMANMZuBB
agent: opus
effort: high
updated: 2026-08-26
next: Run ci, retire this file, open the pull request
---

## Goal

Post-merge adversarial audit of PR #79 — three independent review contexts
(correctness, platform, doctrine-conformance), every finding verified by
running before it was reported, per the diamond rule in
`.agents/docs/graph.md`. This branch repairs what survived: the finish
ritual #79 broke, and two holes in the guard #79 added.

## Decisions

- The stale workstream file #79 left on `main` is removed with the repo's
  own remedy (`cleanup --apply`), first commit, so the repair is the tool's
  answer and not a hand edit.
- Manifest walk gains the runtime-shipped paths (`.agents/env` for every
  selectable layer, root `AGENTS.md` for the marker splice) — the static
  `FILES=(`/`DIRS=(` parse cannot see `DIRS+=` or the splice.
- Dead-entry rule: a manifest entry matching nothing while its path exists
  is a malformed pathspec and goes red; a path absent from the index is a
  legitimately empty dir and only prints. Distinction, because `.claude/`
  trees may be legitimately empty in a future canonical while a stray
  quote in the arrays must never pass.
- Clone-flag tripwires check flag presence on the clone line, not an exact
  literal — a `--quiet` spelling change or flag reorder is
  behavior-preserving and must not go red.
- Consumer-own files inside pinned trees (own `.bat` in a skill checks out
  LF, cmd.exe breaks): documented with the override route and its AHEAD
  cost, not "fixed" — gitattributes has no negation, and any pin narrowing
  reopens the phantom-update class the pins exist to close.

## Rejected

- Hard-failing every zero-match manifest entry: `.claude/commands` and
  `.claude/skills` can be legitimately empty in a canonical that trims
  them; a red run on an empty dir teaches sessions to ignore the step.
- Making the walk parse `DIRS+=` lines generally: the two runtime adds are
  structural (env layer, splice), not incidental; parsing arbitrary bash
  mutation is a second implementation of the engine.

## Review

- r1: #79's merge left docs/handover/upgrade-crlf-phantom-updates.md on
  main — finish-ritual violation, counted by cleanup as 1 removable
  (fixed: cleanup --apply, first commit)
- r2: manifest walk silently drops entries git ls-files does not match
  (trailing blank, quoted entry, tab indent) — wrong PASS with a shipped
  file unchecked; each input verified against the real repo (fixed:
  tolerant parse + dead-entry red)
- r3: walk never visits the runtime-shipped env layer (DIRS+=) or root
  AGENTS.md (splice) — a future pin narrowing passes green while upgrade
  ships CRLF (fixed: both paths emitted explicitly)
- r4: clone-flag greps require an exact literal; behavior-preserving
  refactors flip them to spurious FAIL (fixed: flag-presence check;
  fails loud either way, so severity low)
- r5: synced pins legislate LF for consumer-own files inside
  .agents/.claude trees — own .bat in a skill breaks under cmd.exe,
  verified in a scratch repo; two lenses found it independently (fixed:
  documented in consumer-repos.md with the override route and its AHEAD
  cost — no code change possible without reopening the phantom class)
- r6: `* text=auto` misclassifies NUL-free printable-heavy binaries and
  strips CR at git add — corruption, verified; predates #79, inherited by
  every pin (open: canonical-wide decision, flagged to Chris in the PR
  body, not this branch's to make)

## Blockers

None.

## Where to look

- `.agents/harness/selftest.sh` — step "sync manifest eol pins":
  manifest_paths runtime adds, dead-entry rule, check_clone_flags.
- `.agents/docs/consumer-repos.md` — consumer-own-files paragraph.

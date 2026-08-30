---
workstream: graduate-orchestration-shape
status: review
branch: claude/graduate-orchestration-shape
pr: none
plan: orchestration-shape
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-30
next: Merge once green
---

## Goal

Last open question, answered and verified, never graduated. Its findings
govern how this repo runs N sessions with no coordinator, and they live only
in a node scheduled for deletion.

## Decisions

- Do NOT carry its central number. "19 of 39 merges carried a reconcile" is
  the file's only measured claim, and its window commit `87d130a` does not
  exist in a full clone — so the Method cannot be re-run as written. Replaced
  with a reproducible measurement, not with silence.
- Do not use `--grep=reconcile` as the proxy either. It counts commits whose
  MESSAGE discusses reconciling, which this session has written many of;
  measuring the act means matching the reconcile merge's own subject.

## Rejected

- Carrying 19/39 with a caveat. A number nobody can re-count is a written
  number by this repo's own rule, and hedging it would launder it into the
  doc it graduates to.

## Review

opus, adversarial. Lenses: is the replacement number sound, does the
graduation carry what was verified, and does it withdraw anything that still
holds.

- r1: the file's central number could not be re-run — `87d130a` is not an
  object in a full, unshallowed clone. Checked that before replacing it rather
  than assuming staleness: `git cat-file -e` and
  `git rev-parse --disambiguate` both find nothing. A number nobody can
  re-count is a written number by this repo's own rule, so it is replaced, not
  hedged. (fixed)
- r2: my first replacement proxy was `--grep=reconcile` over commit messages,
  which returned ~10% and is wrong in a way worth recording: it counts commits
  DISCUSSING reconciling, and this session has authored many. Matching the
  reconcile merge's own subject gives 25.4%. Two proxies, 2.5x apart, and the
  plausible one was the wrong one. The graduated text warns against it by
  name. (fixed)
- r3: the new number is stable across two windows (51/201 all-time, 14/60
  recent) which is what makes it usable as a baseline. A single window would
  have repeated the sampling error #138 was about. (no action)
- r4: checked the graduation does not quietly restore any figure the
  verification pass dropped — the 6.7 tasks/second, the 950ms/500ms pair and
  the "nine orchestrators" claim are all absent, and the qualitative costs are
  stated as qualitative. (no action)
- r5: the adopt-or-build question about agent teams is carried as OPEN rather
  than resolved. The research explicitly declined to answer it and said it
  wants a node of its own; graduating it as settled would invent a conclusion
  nobody reached. (no action)

## Blockers

None.

## Where to look

- `.agents/docs/product/README.md` — where it lands, beside Branch flow.

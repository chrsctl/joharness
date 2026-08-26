---
workstream: upgrade-crlf-phantom-updates
status: in-progress
branch: claude/upgrade-crlf-phantom-updates
pr: 79
plan: none
session: https://claude.ai/code/session_01UTCnacqdtMFMweMANMZuBB
agent: sonnet
updated: 2026-08-25
next: Wait for Chris to approve first-fork workflows on PR 79, then his review
---

## Goal

`joharness.sh upgrade` on a stock Git-for-Windows host reports phantom
updates on every run and writes CRLF bytes into the consumer. Found during a
routine Windows pass over the new upgrade route (fresh scratch consumer,
`upgrade --dry-run` against a byte-identical canonical reported
`2 updated`: `.gitattributes`, `.claude/settings.json`). Third find in the
Windows-blind-spot class; the fix must make the shipped files byte-identical
on every platform without legislating line endings for the consumer's own
code.

## Decisions

- Pins scoped to what the harness ships (`.agents/**`, `.claude/commands/**`,
  `.claude/skills/**`, `.claude/settings.json`, `.gitattributes`), NOT a
  catch-all `* eol=lf`: this file lands in every consumer's root, so a
  repo-wide pin would force LF on the consumer's entire codebase —
  .bat/.cmd checked out LF is the known cmd.exe breakage.
- Belt in both canonical-clone sites: `cmd_upgrade` and the `update.yml`
  seed each clone with `-c core.autocrlf=false -c core.eol=lf`. Both flags,
  because they fail separately — autocrlf off still falls back to
  `core.eol` (native = CRLF on Windows) for a future attribute that says
  `text` without `eol`. Empirically confirmed on this host.
- Future-proofing is a selftest, not a comment: the "sync manifest eol
  pins" case walks FILES/DIRS out of the engine's own arrays and fails on
  any shipped file `git check-attr eol` does not resolve to `lf`, so
  extending the manifest without extending `.gitattributes` cannot pass ci.
- python3 JSON case now probes execution before use: stock Windows ships a
  Microsoft Store `python3` stub that `command -v` finds and that fails on
  run — the case read that as invalid JSON, red ci on a clean checkout.
  Fourth find in the class, fixed here because it blocked a green `ci` on
  the platform this branch is about.
- First post-fix upgrade on a pre-fix Windows consumer will report the
  previously-CRLF files as updated ONCE (LF canonical vs CRLF on disk),
  with an empty `git status` for EOL-only rewrites. One-time and
  self-healing; not the phantom loop coming back.

## Rejected

- Catch-all `* text=auto eol=lf` (first version of this branch): review
  caught that the synced `.gitattributes` legislates for the whole consumer
  repo — .bat/.cmd breakage on Windows consumers. Scoped pins keep the
  legislation to harness-owned paths.
- Normalizing inside the sync engine (compare via `git hash-object` or
  strip CR before diff): touches the hot compare loop for every file to
  serve one host default, and hides real CRLF regressions instead of
  preventing them.
- Pinning only the two files that showed: next unpinned shipped file
  reopens the bug; the manifest-walking selftest closes the class instead.

## Review

- r1: synced catch-all `* eol=lf` forces LF on the consumer's entire
  codebase (.bat/.cmd breakage) (fixed: scoped pins)
- r2: widened unchecked `git checkout` in the CRLF fixture turns setup
  failure into vacuous PASSes (fixed: rc checked, check_lf fails on
  missing file)
- r3: `-c core.autocrlf=false` alone leaves `text`-without-`eol` files to
  core.eol = native CRLF on Windows (fixed: `-c core.eol=lf` added)
- r4: by-hand sync route from a pre-fix Windows checkout ships CRLF; no
  renormalization guidance (fixed: consumer-repos.md names the flags and
  the renormalize step)
- r5: consumer with a customized `.gitattributes` reads AHEAD, never gets
  the pins, keeps the phantom loop (open: AHEAD message could name the
  consequence; separate change, engine messaging)
- r6: `update.yml`'s canonical clone lacked the belt and is seeded once,
  never synced (fixed: flags added to the seed)
- r7: belt had zero test coverage (fixed: grep assertions for both clone
  sites in selftest)
- r8: first post-fix upgrade on a pre-fix consumer reports one-time
  updates with an empty diff (fixed: documented in Decisions; no code
  change — self-healing)
- r9: Review section carried a placeholder bullet before any review ran
  (fixed: this section is now the record)
- r10: `*.sh`/`*.md` comments contradicted the catch-all `eol=lf` (fixed:
  catch-all reverted, comments true again)

## Blockers

None.

## Where to look

- `.gitattributes` — scoped pin block at the bottom; top comment says why
  no catch-all.
- `joharness.sh:cmd_upgrade` — clone flags next to the UPGRADE_CLONE
  mktemp.
- `.github/workflows/update.yml` — same flags on the seeded clone.
- `.agents/harness/selftest.sh` — step ".gitattributes" (probes + checked
  checkout), step "sync manifest eol pins" (manifest walk + flag greps),
  python3 stub probe at "boundary block is valid JSON".

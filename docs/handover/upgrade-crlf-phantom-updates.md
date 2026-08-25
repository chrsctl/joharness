---
workstream: upgrade-crlf-phantom-updates
status: in-progress
branch: claude/upgrade-crlf-phantom-updates
pr: none
plan: none
session: https://claude.ai/code/session_01UTCnacqdtMFMweMANMZuBB
agent: sonnet
updated: 2026-08-25
next: Open the pull request once ./joharness.sh ci is green on Windows
---

## Goal

`joharness.sh upgrade` on a stock Git-for-Windows host reports phantom
updates on every run and writes CRLF bytes into the consumer. Found during a
routine Windows pass over the new upgrade route (fresh scratch consumer,
`upgrade --dry-run` against a byte-identical canonical reported
`2 updated`: `.gitattributes`, `.claude/settings.json`). Third find in the
Windows-blind-spot class; the fix must make a stock clone byte-identical on
every platform.

## Decisions

- Root fix in `.gitattributes`: `* text=auto eol=lf`. Pins the checkout
  ending for every text file, not only `*.sh`/`*.md`, so the class dies
  instead of the two symptomatic files. macOS/Linux checkouts are already
  LF — no change for Chris.
- Belt in `cmd_upgrade`: `git clone -c core.autocrlf=false`. The sync
  engine compares working-tree bytes; the canonical checkout must carry
  repository bytes regardless of host config or future `.gitattributes`
  gaps.
- Selftest extends the existing `.gitattributes` step (probe.json +
  `.gitattributes` itself through an `autocrlf=true` checkout) rather than
  adding a network-clone case: `upgrade` hardcodes the https URL, so its
  clone cannot be pointed at a fixture offline.

## Rejected

- Normalizing inside the sync engine (compare via `git hash-object` or
  strip CR before diff): touches the hot compare loop for every file to
  serve one host default, and hides real CRLF regressions instead of
  preventing them.
- Pinning only the two files that showed (`.claude/settings.json`,
  `.gitattributes`): next unpinned text file (YAML, conf) reopens the bug;
  the catch-all closes the class.

## Review

- r1: pending — record edge review before the pull request opens.

## Blockers

None.

## Where to look

- `.gitattributes` — catch-all now `eol=lf`; the `*.sh`/`*.md` pins stay as
  documentation of the two earlier finds.
- `joharness.sh:cmd_upgrade` — clone flag next to the UPGRADE_CLONE mktemp.
- `.agents/harness/selftest.sh` — step ".gitattributes", two new probes.

---
workstream: rescope-settled-by-merged-superset
status: done
branch: claude/rescope-settled-by-merged-superset
pr: none
plan: rescope-settled-by-merged-superset
issue: 300
session: https://claude.ai/code/session_01G5BQQShzZLen4fbuJHnfNY
agent: opus
updated: 2026-10-10
next: verify, retire plan + workstream file, PR, merge
---

## Goal

Issue #300: a merged `done` rescope must settle a later key whose holders
are a subset of its key, unless a held plan's file changed since.

## Decisions

- Subset test is one helper, `dispatch_rescope_covers`, used by BOTH the
  in-flight `done | blocked` rows and the merged records: two readers of one
  rule would drift.
- Merged walk stops at the first (newest) record that settles; later ones
  add nothing to the verdict.
- Built by the manager directly, no workers: one function chain in one file
  plus its suite — splitting it would put two workers on a shared file.

## Rejected

## Review

- r1: (verifier) a plan made free AFTER the record (its `needs:` retired, its own file unchanged) is settled without a surveyor having seen it; the record stores no held set. (wontfix: `wave_split_hit` holds it behind the holder's exclusive claim whatever its own scope says, and the surveyor already judged that claim a genuine edit; storing a held set is changing what the record is, out of scope)
- r2: (verifier) a HOLDER's plan file changing (scope widened) did not invalidate the record — only held plans were checked. Repro: verifier's fx.sh holderedit. (fixed: holders join the changed-since set; fixture "a holder edited since the record re-earns a rescope")
- r3: (verifier) orchestrate.md's cover sentence let a ledger `rescoped=a+b+c` swallow the re-earned spawn on key b after a held plan changed. (fixed: the cover holds until that surveyor merged; a spawn line on a covered key after that earns one more)
- r4: (verifier) the in-flight subset change was pinned by no test: equality left every fixture green. (fixed: fixture "a done rescope on a superset key settles the shrunk key", key gone+keeper vs keeper)
- r5: (verifier) in-flight done rows settle on cover alone, merged ones also need "no plan changed since". (wontfix: an unmerged branch has no retire sha to measure from — its tip..base counts main's edits from before the surveyor concluded; pre-existing for the equal key, plan keeps the in-flight rule as is)
- r6: (verifier) a retire inside a merge commit whose file only parent 2 carried was dropped: `M^:path` does not exist (scratch g2). (fixed: read at ^1, then ^2)
- r7: (verifier) "0 hits without, 12 with" does not re-count. Re-counted 2026-10-10 on origin/main (1738 commits), `git log <flags> --diff-filter=D --name-only --format= origin/main -- 'docs/handover/rescope-*' | grep -c .`: none 0, `-m` 1, `--full-history` 1, both 1. (fixed: comment carries this count and the command shape; REQUIRED claim dropped)
- r8: (verifier) committed fixture wrote into docs/handover after git removed it, and used raw `git rm`. (fixed: mkdir -p, retire through `fixture_rm`)
- r9: (verifier) new helper used the "$(...)" + "<<<" pairing the Trap forbids. (fixed: process substitution for the log and the field read)
- r10: (verifier) a failing `git log` on sha..base read as unchanged and settled. (fixed: a failed read sets mchanged, settles nothing)
- r11: (session) `./joharness.sh ci` → `ci: pass`, selftest 2363 passed, 0 failed (2026-10-10). Revert check: origin/main's joharness.sh with this suite → 2355 passed, 8 failed, the first merged fixture among them. `./joharness.sh verify` → first run 5 passed, 1 failed (docker could not pull alpine:3 — registry/egress, layer untouched by this diff), re-run 6 passed, 0 failed. (no change)

## Blockers

None.

## Where to look

- `joharness.sh:cmd_dispatch` — overlap-bound block.

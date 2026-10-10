---
workstream: guard-before-a-harness-push
status: in-progress
branch: manage/guard-before-a-harness-push
pr: none
plan: guard-before-a-harness-push
issue: 398
session: https://claude.ai/code/session_018Vxqi4MSVT8L68UTbCoig4
agent: opus
updated: 2026-10-10
next: Retire plan and workstream file, open the PR, merge
---

## Goal

One shared check (`./joharness.sh guard <verb> <branch> [--expect <sha>]`)
run right before every harness push onto a branch the session does not own,
so "re-read live state before writing" is a property of the write path
(#397, #398).

## Decisions

- Exit codes: 0 pass, 2 = `live` found the branch gone (released already),
  1 = every other refusal. janitor_apply needs the split: gone stays rc 0 and
  drops the stale local ref (PR411 r3); unreachable stays a failure.
- janitor_apply calls guard where the inline check was, before the candidate
  filter and the build: gone must win over not-a-candidate (r3). Building is
  local; the lease covers the window to the push. A pr: claim now reads as a
  guard refusal, not `not a candidate`.
- `claim` reads workstream files the branch wrote since its merge base (as
  `cl_inflight`), both sides; head refusal stays the refusal.
- orchestrate.md: one GUARD paragraph, referenced from KILL, LOOP, the
  relayed human answer and the respawn-limit hand-off.

## Rejected

- None yet.

## Review

- r1: shellcheck SC2183, the fixture claim's printf took five arguments for four placeholders. (fixed)
- r2: mutation, 2026-10-10: each guard check disabled in turn (base-name protected, live gone, live unreachable, head, pr: protected) and the guard topic alone run through a scratch runner sourcing `.agents/harness/selftest/guard.sh`: 8, 2, 1, 9, 4 failures; unmutated 44 passed, 0 failed. (no change)
- r3: (verifier) janitor --apply ran guard after the candidate filter, so a branch gone on origin that was no candidate (pr: set, pushed recently) read `not a candidate`, rc 1, stale ref kept — PR411 r3 regressed. (fixed: guard runs where the inline check was, before the build; selftest case mgr-deletedpr)
- r4: (verifier) `--expect` naming a commit not in this clone passed every check: the pr: read failed into `continue`. (fixed: an unresolvable decision read refuses at head; the failed-read refusal at protected is a backstop no test reaches, since head now needs live = a local expect)
- r5: (verifier) the claim fetch moved refs/remotes/origin/<b>, so a bare re-run took the live head as its decision and passed with no re-decide. (fixed: fetch with empty --refmap, FETCH_HEAD only; selftest re-run case)
- r6: (verifier) plan Acceptance `grep -c 'joharness.sh guard' .claude/commands/orchestrate.md` printed 0: the code span broke across lines. (fixed: one line, count 1)
- r7: (verifier) an `--expect` starting with `-` reached `git show` as an option and wrote a file. (fixed: usage error; the raw value never reaches git)
- r8: (verifier) orchestrated.md said a lease guards orchestrator pushes, but orchestrate.md pushed plain; a branch deleted after guard would be re-created. (fixed: GUARD names the leased push at the same sha)
- r9: (verifier) GUARD's `<sha>` undefined for the relayed answer and the hand-off, and a fresh fetch right before guard makes it unable to refuse. (fixed: sha = origin/<branch> right after the decision's fetch, never a later one)
- r10: (verifier) the new heading swallowed the kill section's `A refused stop` paragraph. (fixed: moved above the heading)
- r11: (verifier) claim loop read `$(...)` back through `<<<`, the pairing PR359 r9 dropped. (fixed: process substitution)
- r12: mutation re-run after r3–r11, 2026-10-10, same scratch runner: unmutated 51 passed, 0 failed; base-name 8, live gone 2, unreachable 1, head 12, pr: 4, refmap reverted 3 failures; full `bash .agents/harness/selftest.sh` 2457 passed, 0 failed. (no change)
- r13: (verifier) the r5 fix left a narrow-refspec clone refusing a moved branch on every `janitor --apply`: nothing moved the stale tracking ref. (fixed: --apply fetches each named branch into its tracking ref as its decision read; selftest mgr-movednarrow. 2026-10-10, janitor+guard topics through the scratch runner: 142 passed, 0 failed; that fetch removed, 2 failed; full selftest 2462 passed, 0 failed)
- r14: (verifier) GUARD's decision fetch was `git fetch origin <branch>`, which under a narrow refspec moves FETCH_HEAD only, and the answer and hand-off rows named no fetch. (fixed: explicit refspec fetch, run before the checkout for every write)
- r15: (verifier) the r4 test used an arbitrary sha the old code also refused; the real input (live sha never fetched, pr: claim) was untested. (fixed: g-prmoved case)

## Blockers

None.

## Where to look

- `joharness.sh:janitor_apply` — the push path guard replaces the inline check in.

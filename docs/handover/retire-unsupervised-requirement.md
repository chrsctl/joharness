---
workstream: retire-unsupervised-requirement
status: in-progress
branch: claude/unsupervised-slim-down-nqfie4
pr: none
plan: retire-unsupervised-requirement
issue: none
session: https://claude.ai/code/session_017oZ8o5q2YRzjFT1eTnx4Cs
agent: opus
updated: 2026-09-03
next: Move the three rules into Bounds, repoint 16 citations, delete the requirement, run ci and verify.
---

## Goal

"Do we still need docs/product markdown" — clarified: the requirement
inside it. Researched, and the answer is no, but not by deleting a file:
its permanent rules are cited 14 times by running code.

## Decisions

- Retire by RELOCATION. The file mixes a completable spec with permanent
  rules; only the spec completes. Three rules move to
  `.agents/docs/unsupervised.md`, two are already there in full and just
  lose their second copy, then the file goes.
- The endurance bullet is not a code deliverable and has not been since
  PR 202 made drain-only. Length is the heartbeat's, the heartbeat is an
  operator action, and #165 tracks it. Retiring the spec does not retire
  the goal — it moves it to where operator work lives.
- The false bullet a verifier round found (r1/r2 of the abandoned branch)
  is disposed of by deletion rather than fixed. Named in the plan's Out of
  scope so it is a decision, not a convenience: I could not fix it without
  rewriting the requester's words, and deleting the file removes the claim
  along with everything else.
- This branch previously held `byte-identical-bullet.md`, an abandoned
  attempt to fix that bullet. Its blocker — the human must decide about
  their own words — is dissolved by retirement, so its file is deleted
  here. Its findings are in this branch's history
  (`git log --diff-filter=D -- docs/handover/byte-identical-bullet.md`).
- Written as a same-session plan first, unlike that attempt. The verifier
  found it building unplanned against step 2, and it was right.

## Rejected

- Deleting the requirement alone. Four runtime messages would cite a path
  that does not resolve, including the one a session reads when the guard
  blocks its stop.
- Keeping the file so the citations stay valid. That keeps a completable
  spec alive as a citation target forever, and keeps two rules in second
  copies.
- Moving the rules into `.agents/harness/AGENTS.md`. That file is the Loop,
  kept short on purpose; the mode's rules have a home already.
- Fixing the false bullet first, then retiring. The fix is moot once the
  file goes, and the fix itself is the requester's call.

## Review

Carried forward from the abandoned `byte-identical-bullet` record this
branch deletes. Twelve of its thirteen findings were dispositioned there;
one was left open, and the finding-verdicts gate correctly redded this
branch for deleting the file that held it.

- r5: (verifier) uncorrected copies of the byte-identical claim remain —
  the Goal's "supervised stays the default and stays exactly as it is" six
  lines above the bullet, plus two selftest comments citing the
  requirement's wording, two of which say "Acceptance" where a requirement
  has `Satisfied when`. (fixed by this branch: the Goal goes with the file,
  and both comments are now in the plan's Scope — they are citations of a
  file that will not exist, the same defect as the path citations this
  plan already repoints)

## Blockers

None.

## Where to look

- `docs/plans/retire-unsupervised-requirement.md` — the spec for this work.

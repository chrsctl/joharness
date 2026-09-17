---
workstream: retire-orchestrated-run
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Verify, retire this file, open the pull request and merge; then drain the next item
---

## Goal

Requester, 2026-09-17: remove `docs/plans/orchestrated-run.md`, because the
live orchestrated run is being done in a child repo rather than here. Asked
what should become of the requirement that plan served, the requester
answered: **mark as done.**

No plan for this work, and that is deliberate — the one carve-out the Loop
names is a diff that describes itself. This is a removal the requester
decided and a record moved, not a build. Writing a plan to delete a plan
would be the ceremony, not the protocol.

## Decisions

- **Retire the requirement, do not leave it standing.** The queue hook ranks
  a requirement no open plan serves ABOVE every plan
  (`.agents/harness/queue-context.sh`, the `unplanned` block). Deleting only
  the plan would have put `orchestrated-mode.md` at the top of the next
  `/drain` labelled `UNPLANNED — decompose into plans`, and the honest
  decomposition of it is the plan just removed. The requester was asked
  before this was done.
- **Done means retired, here as everywhere.** The repo has no status field
  by design — "no state store, no status field: every view derives from git
  and the control plane at read time" is the requirement's own constraint.
  So "mark as done" is the same lifecycle a plan or a research node gets:
  the record moves to the layer doc, the file goes, history keeps it.
- **The fourth condition is recorded as measured elsewhere, not as met.**
  Three of four `Satisfied when` bullets read true and each is documented in
  `.agents/docs/orchestrated.md`. The fourth — one run, started once over a
  stocked queue, counted until it stops — has never been met by any run, and
  saying otherwise to close a file would put a false claim in the one
  document a later reader trusts. What closed is this repo's scheduling of
  it.
- **The requester's transcribed words are carried verbatim**, not
  paraphrased. They are the only part of that file a later reader cannot
  reconstruct, and the section says it is a transcription and how the
  session came to keep it.

## Rejected

- **Deleting the requirement without carrying it.** Step 7 allows the
  deletion and says still-useful bits go to the right layer first. The ask
  and the four conditions are the useful bits; `git log --diff-filter=D` is
  a recovery route, not a reading route.
- **A `status: done` line in the requirement's frontmatter.** No reader
  parses one, the hook's test is whether an open plan names the requirement,
  and the requirement's own constraints forbid a status field. It would have
  left the file at the top of the queue while looking handled.

## Review

- (none yet)

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh`, the `unplanned` block — why the
  requirement could not simply be left behind.
- `.agents/docs/orchestrated.md`, Where the mode came from — the new home.

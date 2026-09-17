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
next: Retire this file in the last commit before the pull request, then merge and drain the next item
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
  the plan would have put `orchestrated-mode.md` above every plan in the next
  `/drain`, labelled `UNPLANNED — decompose into plans` (edge work and the
  janitor line still print above it), and the honest
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

- r1: (verifier) **the deletion writes a git signal that means SATISFIED,
  which is the only deletion route the rule defines.**
  `.agents/docs/product/README.md` lists four lifecycle states and exactly
  one that deletes: "**Satisfied** = last plan's PR deletes the requirement
  file with the plan file." This PR does precisely that, byte for byte,
  while the layer doc says "No run has met it". Two readers encode the same
  equation: `joharness.sh:2543` warns `requirement '<r>' gone from tree —
  satisfied while this plan is open?` and `joharness.sh:7693` (curate
  DECLUTTER) says `its requirement '<reqstem>' is gone and no other plan
  serves it — satisfied? confirm in merged history, then delete`. Neither
  fires today — all four remaining plans read `requirement: none`, checked —
  so it is latent, not live. (fixed — `product/README.md` gains the fifth
  state this diff created the first instance of: **Retired unsatisfied**.
  Both readers ASK rather than assert, and the answer they send a reader to
  now exists. The verifier also put on record that it found no overreach on
  authority: the requester was asked and answered, which is what Decide
  alone requires; what was missing was the rule text, and that is what this
  fixes.)
- r2: (verifier) **the repointed reference in `.claude/commands/orchestrate.md`
  points at a section that does not contain the claim.** It says a measured
  run flips the mode through a pull request and cites the new section, which
  says nothing about flipping `JOHARNESS_MODE`, `joharness.conf` or a pull
  request — grepped, zero matches. The old pointer was TRUE; my replacement
  is not, in step 0 of the file an orchestrator reads at every start, which
  ships to every consumer. (fixed — repointed at Bounds, which carries the
  claim in its own words.)
- r3: (verifier) **"its row lands in Runs above when that run ends" is an
  obligation no node carries.** The plan whose Scope said to record that row
  is the file this PR deletes; no plan, requirement or research node
  replaces it. A promise in prose with nothing scheduling it is state stored
  in prose, which `.agents/docs/graph.md` forbids. (fixed — the sentence now
  says what would close the condition and that nothing here schedules it,
  which is the true statement.)
- r4: (verifier) **"What it was satisfied by" asserts satisfaction in its own
  bolded lead-in**, six lines above the text denying it, and bold is what a
  skimmer reads. The workstream file's own Decisions section says preventing
  exactly this was the point. (fixed — the lead-in now counts the three.)
- r5: (verifier) a false see-above: condition 2 is sourced to "The loop",
  which documents that dispatch is read and that holds are skipped, and
  documents neither push age nor the cap nor the verdict line. The section
  that carries all three is the `dispatch` row in "What the mode changes".
  (fixed — repointed. The verifier checked the other two pointers and both
  hold.)
- r6: (verifier) "each already has its own home above" is false for one of
  four: the no-state-store / no-status-field constraint has no named
  section, and the no-status-field half — the premise this whole retirement
  rests on — is stated nowhere else in the file. (fixed — that constraint is
  written out here in full and named as having no other home, rather than
  pointed at one that does not exist.)
- r7: (verifier) two commit hashes were dropped that were the only pointer to
  where two deleted plans went. The requirement carried "(`e1ec240`,
  `8e637aa`)"; Runs names both plans by path and neither file exists.
  Verified: both hashes resolve, and neither appears anywhere in the tree
  now. `consumer-repos.md` exempts commit hashes from the naming rule
  explicitly, so there was no reason to drop them. (fixed — both restored
  beside the sentence that needs them.)
- r8: (verifier) the recovery command ships to consumers, where that path
  never existed and it prints nothing with no caveat. `.agents/docs/` is in
  the sync's ship list. The precedent for the caveat is one directory over
  in `product/README.md`: "a consumer carries this page but not that
  history". (fixed — same caveat, same words.)
- r9: (verifier) three references to the deleted plan were left dangling
  where one was repointed: Runs' "per the plan's own rule", "what the plan
  said a run without a Routine would measure", and "the plan says a run
  without a Routine". Until this diff a reader could resolve them with one
  `git grep`. (fixed — all three repointed at the retired file by name.)
- r10: (verifier) **`## Review` held the literal line `- (none yet)`, which
  three readers count as a real, unanswered finding** — `ci` reports it as a
  finding nothing can key on AND as a finding with no verdict, `review`
  counts 1, `scorecard` counts 1 unmarked. The template says it outright:
  leave none here unfilled. `JOHARNESS_REVIEW=off` here so `ci` does not
  red, but a fake finding enters the record `feedback` serves back for ever.
  (fixed — replaced by these.)
- r11: (session) the verifier's own precision note, taken: the workstream
  file said the requirement would land "at the top of the next `/drain`".
  Edge work in flight and `janitor : DUE` both print above it. (fixed —
  "above every plan", which is what the code does.)

## Blockers

None.

## Where to look

- `.agents/harness/queue-context.sh`, the `unplanned` block — why the
  requirement could not simply be left behind.
- `.agents/docs/orchestrated.md`, Where the mode came from — the new home.

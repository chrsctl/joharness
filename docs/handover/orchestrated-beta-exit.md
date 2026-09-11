---
workstream: orchestrated-beta-exit
status: review
branch: claude/remove-beta-flags-p31tgj
pr: none
plan: orchestrated-beta-exit
issue: none
session: https://claude.ai/code/session_01D2wRwGfjpFu5MfRsHh6jt7
agent: opus
updated: 2026-09-11
next: Retire this file and the plan file, open the pull request, drive it green, merge
---

## Goal

Requester, 2026-09-11: "There are still (beta) flags; remove". Direct human
ask against `docs/plans/orchestrated-beta-exit.md`, which is why this runs
ahead of its `needs: orchestrated-run` edge — the edge buys a number, and
the plan's real gate was always the human's answer below, not the DAG.

## Decisions

- **The gate, and exactly who decided what.** The plan's first Acceptance
  bullet is a hard stop: put licences A, B and C to the human as written and
  get one answer. Asked 2026-09-11 with all three quoted and each one's truth
  value counted — A undischargeable as written, B true, C false. The human
  answered **"We want to remove the beta"**: a decision to remove, naming no
  licence. Choosing B among the three was then the SESSION's inference, made
  under that instruction, on the ground that B is the only one of the three
  that reads true. Recorded this way on purpose — an earlier draft of this
  file claimed the human picked the licence and separately claimed the
  session had not, which cannot both be true (r7).
- **Two dates, and they are not the same date.** Run 1 ran **2026-09-06**.
  The label came off **2026-09-11**. Both docs say the second; a reader of
  this file alone once could have taken the first (r10).
- **A is rewritten, not deleted.** A said "beta until a run shows which
  empties a queue faster" — comparative, and neither design has drained a
  stocked queue, so it could never be discharged as written. It now states
  that gap instead of pretending to be the gate the label waited on.
- **A and B make ONE claim in one spelling**: "Run 1 — 2026-09-06 … is the
  counted run, and counting it is what discharged the beta label,
  2026-09-11." The two differ only in how each points at the Runs table;
  checked by normalising whitespace and comparing the extracted sentences.
- **C stays false and stays out of scope.** The requirement's last
  `Satisfied when` — drain the stocked queue, no human turn — is owned by
  `docs/plans/orchestrated-run.md`. Run 1 failed it in its own words ("the
  queue did not drain", 30 plans waiting). Out of beta is a claim about
  evidence; the requirement's drain bullet is a separate, still-open claim.
- **Not the default anywhere.** Not the conf value, not `run_mode`'s
  fail-closed fallback, not the consumer bootstrap. Separate decision, asked
  2026-09-10, still unanswered.
- **One site taken outside the plan's declared `scope:`.** `docs/plans/
  orchestrated-run.md:24` said "Beta defaults are written there" — the same
  stale label, missed because the plan's Acceptance grep covers only
  `joharness.sh joharness.conf .agents .claude`. Taken, because leaving it
  ships the word the requester asked to remove; recorded here rather than
  done quietly (r11). That plan also declares `joharness.conf`, which this
  branch touches — a reconcile at step 7 is expected, not a collision.

## Rejected

- **Asking the human to pick a licence a second time.** They had answered.
  Re-putting A/B/C after a clear "remove the beta" would be re-litigating a
  decision already made; the honest repair was to record the inference as the
  session's, which is what Decisions now does.
- **Deleting licence A.** It carries a real, still-unmeasured gap. Deleting
  it would have made the discharge read cleaner by dropping the evidence
  against it.

## Review

Depth: opus, adversarial. `.claude/agents/verifier.md` spawned at opus; its
findings are tagged `(verifier)`.

- r1: `.agents/docs/orchestrated.md` asserted the comparison "never was what
  the label waited for". False against this file's own prior text — licence A
  tied the label to exactly that comparison. The strip would have had the repo
  rewrite its own history to make the discharge read cleaner. (fixed: the file
  records what condition it used to set and that the comparison stays open.)
- r2: **this finding, as first written, was false, and is corrected here.** It
  claimed the two discharge sentences carried two spellings ("on 2026-09-11"
  against ", 2026-09-11"). At `8f24362` both files read `discharged the beta
  label on 2026-09-11` identically; there was no divergence, and the "check by
  normalising whitespace" it cited would have shown that. It produced a
  harmless comma change, which stands. (fixed: the record says what happened;
  found by r4.)
- r3: the authority paragraph said "nothing about this mode's standing softens
  it" — "standing" is a noun for the label used nowhere else here. (fixed.)
- r4: (verifier) r2 was false against the commit it claimed to fix, and its
  `…` elided the very text it turned on, so no later reader could re-run it.
  `feedback` serves these bullets back to whoever next edits the file, so a
  fabricated finding teaches a defect that never existed. (fixed: r2 rewritten
  above as a withdrawal, with the real history in it.)
- r5: (verifier) "the knobs are still off by default" is false against the
  knob table 20 lines above it — six of seven carry live numeric defaults
  (cap 4, stall 45, health 10, respawn 2 …); only `JOHARNESS_UPSTREAM_FEEDBACK`
  is a switch. An operator who read it and set nothing gets a cap of 4, not
  nothing. (fixed: the claim is about the MODE being off unless a repo sets
  it, which is what the paragraph meant and the wrong subject to state it on.)
- r6: (verifier) `.agents/docs/product/README.md` declared the run counted
  immediately after the criterion that paragraph sets for it — "fewer
  collisions taken, or the hold rule bought nothing" — while deleting the
  sentence that had kept that test open. Run 1's row counts no reconciles at
  all. (fixed: the paragraph now says run 1 did not move that number and why.)
- r7: (verifier) the gate was recorded as answered by an answer naming no
  licence, and `## Decisions` and `## Rejected` contradicted each other about
  who chose B. (fixed: Decisions states the human's words verbatim and names
  the licence choice as the session's inference under that instruction;
  the false Rejected bullet is gone.)
- r8: (verifier) "This file tied that label to a second condition too" was
  wrong about `orchestrated.md` — the comparison was the ONLY condition that
  file ever stated; B lived in `product/README.md`. The sentence written to
  stop the repo rewriting its history misstated it in the other direction.
  (fixed: "the condition this file used to set was a different one".)
- r9: (verifier) "Changing that is a plan, not a side effect of this one"
  dangled — "this one" had no antecedent, and it pointed at a canonical-only
  plan file that is deleted at step 7, in a doc that ships to consumers.
  (fixed: sentence dropped; the following sentence already says it.)
- r10: (verifier) this file gave a third "when" — "what discharged the label
  (run 1) and when (2026-09-06)" — against both docs' 2026-09-11, and its
  "one sentence each" was no longer true of A. (fixed: Decisions separates the
  run date from the discharge date and drops the sentence count.)
- r11: (verifier) `docs/plans/orchestrated-run.md` was edited but uncommitted
  and sits outside the plan's declared `scope:`. (fixed: committed
  deliberately, recorded in Decisions as a scope extension with its reason and
  the reconcile it implies.)
- r12: (verifier) "no peer-fleet drain has ever been measured" is contestable
  against `unsupervised.md` Runs row 1 — 2026-08-30, 53m, "bounded work ran
  out", two merges. Either that is a drain number or the docs should say why
  it does not count; neither was done, in a repo whose own rule is to trust
  counted numbers over written ones. (fixed: both docs now say neither side
  has drained a STOCKED queue, and name the 2026-08-30 row as the nearest peer
  number — two items in one generation.)
- r13: (verifier) plan Acceptance bullet 2 asks the grep to return no hit
  naming this mode beyond three protected sites, but the same plan requires A
  to be rewritten rather than deleted, and the rewritten sentences name the
  label to say it is gone. The plan contradicts itself. (wontfix: the two new
  sentences are the discharge record and are required by the plan's own Scope
  line; recorded here so the next reader who re-runs the grep does not read
  the acceptance as red.)
- r14: (verifier) `next:` was stale and the consumer-side Acceptance bullet
  was unrecorded. (fixed: `next:` updated; the consumer run is under Where to
  look — bootstrapped a scratch consumer at `--mode orchestrated`,
  `session-start` printed `== Mode: orchestrated ==`, `ci: pass` there.)
- r15: (verifier) "That comparison is still open. It is not a label." — "It"
  parsed as either the comparison or the label, in the one sentence whose job
  is keeping them apart. (fixed: "it is not what the label meant".)

## Blockers

None.

## Where to look

- `docs/plans/orchestrated-beta-exit.md` — the three licences, scope, traps.
  Deleted in this branch's retire commit; recoverable from history.
- `.agents/docs/orchestrated.md:Runs` — run 1, which discharged the label.
- `.agents/docs/unsupervised.md:Runs` — the peer runs, and the 2026-08-30 row
  that is the nearest thing to a peer-fleet drain number.
- Consumer check (plan Acceptance, last bullet): `bootstrap-consumer.sh --env
  none --mode orchestrated` into a scratch repo, then `session-start` →
  `== Mode: orchestrated ==`, and `./joharness.sh ci` → `ci: pass` there.
- `.agents/harness/selftest/orchestrated.sh:75` — pins the banner. Proven:
  banner alone reverted, suite went 1770/1 on exactly that case.

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
next: Retire the plan and this file, open the pull request, hand the merge decision to the human.
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

Round 1, verifier at opus, 15 findings. Three were serious.

- r1: (verifier) `cmd_drain`'s NOT YOURS block — one of the four runtime
  citations — repointed the PATH and left the SECTION: it sent a session to
  `.agents/docs/unsupervised.md, Constraints`, which does not exist. The
  nearest name is `## Not constrained, by decision`, so a session asking
  what it may not commit would have read the list of what deliberately is
  NOT forbidden. This is the plan's own Trap 3, and the same shape as
  PR202 r2 on the same file. (fixed: `Bounds`, and verified by running it —
  scratch clone with `origin/main` set to this branch and a fixture plan
  scoped to `joharness.sh`)
- r2: (verifier) a FIFTEENTH citation, `joharness.conf`, never repointed —
  and the plan's Acceptance grep could not see it, because
  `--include='*.sh' --include='*.md'` excludes `.conf` by construction.
  (fixed: repointed, and the acceptance grep drops the filters)
- r3: (verifier) a rule was LOST, not moved: "Propose them with evidence;
  never add them on a session's own judgment." The design doc's
  `Not constrained` records what was declined; the requirement's version
  forbade a session re-taking the decision. It is the rule that makes
  issue 165's budget the human's. (fixed: restored, with why)
- r4: (verifier) two selftest comments were repointed to cite `Bounds` for
  a mode-parity rule Bounds does not carry, and one stated the cross-tree
  claim an earlier round found false — so r5 was re-attributed, not
  addressed. (fixed: both describe what their own cases assert, citing
  nothing they do not carry)
- r5: (verifier) `.agents/docs/unsupervised.md` still asserted "Supervised
  output is byte-identical", contradicting the `drain` row four lines
  below. With the requirement gone the only surviving copy was
  session-authored. (fixed: says what is true — one tree, no mode branch
  changes it, and removing the machinery changes it like any other edit)
- r6: (verifier) the retirement does not meet the lifecycle it cites: no
  plan named this requirement, the endurance bullet reads NOT shown, and
  the queue said decompose rather than delete. (wontfix, and flagged to the
  human in the pull request: they asked about this file specifically and
  said implement, after being shown that the two options were retire or
  leave it — so the deletion is delegated, not assumed. What the finding is
  right about is that "satisfied" is being read as "the harness delivered
  everything it can", which is a reading and not the README's definition.
  The substance — that the open bullet must not evaporate — is answered by
  r7, which makes the rehousing real. If the human reads the delegation
  differently, `git revert` restores the file and the branch is one commit)
- r7: (verifier) the plan said it "adds a comment" to issue 165 and no
  such comment existed. (fixed: posted, and it carries what the issue
  needs to stand alone now that the file it quotes is gone)
- r8: (verifier) two comments repointed the path and left "the requirement
  draws it at can-it-be-finished" dangling. (fixed)
- r9: (verifier) both sites quote "the queue offered an unsupervised fleet
  a plan it could never finish" as a direct quotation from a document that
  never contained it. (fixed: stated plainly, attributed to nothing)
- r10: (verifier) the `## Measured` block gave a false reason for not
  checking the one broken citation — the message is a literal in this
  branch's own `joharness.sh`, so the base ref never supplied it, and it
  was observable all along. That sentence is why r1 went unseen. (fixed:
  all four verified by running them)
- r11: (verifier) the plan's "seven of eight bullets" contradicted its own
  Out of scope, and "pins" overcounted two field observations. (fixed:
  counted by kind)
- r12: (verifier) Bounds bullet 1 restated the queue-hook table row twenty
  lines above it — a second copy inside the file whose Trap forbids a
  third. (fixed: the rule stays, the mechanism points at the table)
- r13: (verifier) the one-distinction paragraph enumerated five pieces,
  omitted the marking, counted two `drain` lines separately, and then
  reasoned about "a sixth". (fixed: the table is the list)
- r14: (verifier) the relocation ships to consumers, and carried an
  unqualified "issue 165" that resolves to a different issue in every
  consumer, plus a canonical SHA. (fixed: both qualified as canonical)
- r15: (verifier) the `## Review` record held only a finding carried from
  another branch's diff. (fixed: this section)

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

## Measured

On the branch, 2026-09-03: `JOHARNESS_SELFTEST=always ./joharness.sh ci`
1221 passed, 0 failed, 1 skipped, `ci: pass`; `./joharness.sh verify`
6 passed, 0 failed. All FOUR runtime citations verified by running
them: the session-start banner, `lint_requirement_writes`'s printed line,
the guard's `add_fact`, and `drain`'s NOT YOURS block — the last in a
scratch clone whose `origin/main` is this branch, with a fixture plan
scoped to `joharness.sh` so the block fires. All four name
`.agents/docs/unsupervised.md, Bounds`.

## Blockers

None.

## Where to look

- `docs/plans/retire-unsupervised-requirement.md` — the spec for this work.

---
workstream: consumer-issues-to-research-nodes
status: in-progress
branch: claude/consumer-issues-to-research-nodes
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_011v7iQ91Wf8TyxVFzQceszb
agent: opus
updated: 2026-10-08
next: Record the verifier's findings in ## Review, retire this file, open the pull request — never merge it
---

## Goal

Direct human ask: convert the open issues filed from a consumer on
2026-10-07/08 into queue items the orchestrated loop can claim. Loop step 2 is
the rule it serves — `./joharness.sh dispatch` reads `docs/plans/` and
`docs/research/` on `main` and never GitHub issues, so an issue is invisible
to the orchestrator that runs here. The conversion IS the work; this branch
writes no harness code and fixes nothing. Precedent: `605557b7` (five issues
to plans and research) and the node `bash-guard-reads-prose-as-a-loop.md`,
which is a consumer report canonical decides on.

Nine issues: #296, #297, #298, #300, #303, #304, #305, #307, #283. The pull
request is for the human to merge, not this session.

## Decisions

- `issue: none` in the frontmatter, deliberately — same reason the precedent
  gave: the field holds one number and this work converts nine, so naming one
  would tell another session the other eight are free. Each node carries its
  own issue number in its text, which is what lets the merge that ANSWERS a
  question close it.
- **Nine nodes, one per issue. None merged.** The closest pair is #283
  (can any signal dispatch reads support a death verdict) and #298 (is there
  any ceiling on an item's time and money). #298 calls itself a companion to
  #283 and its item 3 IS #283's comment — one shared sub-item, the time floor
  under the frozen-cost test. That sub-item lives in the #283 node, because it
  is a liveness threshold; #298's node points at it rather than restating it.
  Two questions, two graduation targets, one cross-reference.
- **Research nodes, not plans, for all nine — and three of them are close
  to buildable.** #296, #303 and #304 each name a fix small enough to carry an
  Acceptance. They are filed as nodes because the ask was a conversion to
  nodes and because each still holds one decision a build would make silently:
  #296 which base ref the count reads and what an unreadable one does (I
  measured the proposed patch failing OPEN); #303 whether the gate is worth a
  selftest line; #304 where the clause goes. Flagged in the pull request body
  so canonical can convert any of them to a plan without re-reading the
  issues.
- **No consumer repository, plan name, item name or pull request number in
  any node** (`.agents/docs/consumer-repos.md`, "Name no consumer"; the
  precedent applied the same rule to `docs/`). Measurements are cited as
  measurements — the counts, the dates, the commands.
  The consumer's pull request numbers are left out even though they are now
  explicitly NOT covered: #273's contradiction was settled on `main` in the
  direction that exempts them (merged mid-branch, and reconciled into this
  branch), and nothing in any node needs one — the issues' measurements are
  anchored by date, time and count. An earlier draft of this bullet gave
  avoiding that contradiction as the reason; the contradiction is gone and the
  choice stands on its own.
- **Every claim read from this repo's source was re-run at `cb0028e`**, not
  copied from the issue. Line numbers in the issues were written against an
  earlier `main`; the ones that moved are given as content, not numbers.
  Measurements taken on a consumer's live fleet are marked
  reported-not-re-measured, as the issues themselves mark them.

## Rejected

- One node merging #283 and #298. They share one sub-item and nothing else:
  #283 is about whether a signal can carry a verdict, #298 about whether a
  spend has a ceiling. A merged node would graduate to two files, and the
  shared time floor would be found by whoever took it rather than by whoever
  needs it.
- Writing #296, #303 and #304 as plans despite the ask. Each would then need
  an Acceptance naming the decision it has not made — which is the shape
  `.agents/docs/research/README.md` exists to catch. Flagged for canonical
  instead.
- Re-measuring the consumer's fleet numbers. Not possible here, and the
  issues say so themselves. Invented numbers would read as a record.

## Review

Depth: opus, adversarial (`./joharness.sh review`). `JOHARNESS_REVIEW=off`, so
`ci` does not check this section; it is written because the gate being off is
not a reason.

Rounds 1-2 are this session reading its own diff. Round 3 is
`.claude/agents/verifier.md` at opus — one reader that did not write the diff,
which re-ran every node's `## Method` itself, built its own fixture for #296
and ran the full selftest patched and unpatched. Its findings are tagged
`(verifier)`. Four of them refute a claim this branch had already published,
which is the property the independent read exists for.

Self-found, round 1-2 — fixed in the commits named, which landed before the
independent read returned:

- r1: Two nodes claimed every respawn the health table orders requires the
  session to be GONE. The LOOP row acts on a manager that is alive and pushing.
  Restated: the gap is that its one row for a working manager measures
  repetition, not spend. (fixed, `ca5f442`)
- r2: `no-ceiling-on-one-item` inferred that the reported item's `next:` was
  moving. The issue does not report it, so whether the LOOP row's second clause
  could have matched is unknown. (fixed, `ca5f442`)
- r3: `#296`'s Method omitted the git identity and ran the guard by a relative
  path, which resolves to the fixture's own missing copy — not re-runnable as
  written. (fixed, `ebbec96`)
- r4: `ledger-fields-with-no-rebuild` called three differently-worded
  statements of one rule "the same sentence". (fixed, `ebbec96`)

Round 3, the independent read:

- r5: `push-age-is-not-death`'s load-bearing comparative claim — "the only
  place in the harness that recommends a respawn from a single reading" — is
  false. Two rows do: `orchestrate.md:182` (ARCHIVED or not found by title, one
  control-plane read) and `:177`'s LOOP first clause (churn past the limit on
  one pass), the second of which kills a LIVE session. This is the sentence the
  `urgency: urgent` mark rested on. Restated on the axis that survives both —
  what the reading is ABOUT, not how many there are — and the urgency paragraph
  with it. (verifier) (fixed)
- r6: Same node, drifted number inside the urgency argument: "three times out
  of three" is push age's record as a SIGNAL; the destructive row printed on
  two of three. (verifier) (fixed)
- r7: `plan-on-an-unmerged-branch`'s own "not yet run" command was written in
  the pipe form that a finding three paragraphs later quotes as a paid-for
  race. Rewritten in the shape `joharness.sh:7951-7956` prescribes.
  (verifier) (fixed)
- r8: Same node, "the queue is read from `origin/<base>` and from nowhere
  else" omits `queue-context.sh:182-200`, a third branch walk in the hook
  itself — and it is the most natural home for the row the issue wants. Now a
  finding of its own. (verifier) (fixed)
- r9: Same node, the quoted code block spliced line 67 onto 75-76 and dropped a
  two-line comment, against `.agents/docs/caveman.md` `## Never touch`
  ("Code blocks — byte-exact. No comment removal"). (verifier) (fixed)
- r10: `guard-fires-on-an-empty-branch` asks whether a selftest case is owed
  while its own Method grep returns one that already exists
  (`selftest/handover-guard.sh:400`). The reader also measured the suite with
  and without the patch — 2211 passed, 3 failed, 1 skipped both ways — which
  is the fact the bullet asked for. Added as a finding. (verifier) (fixed)
- r11: Same node, "blocks with the same fact" is incomplete: the one-commit
  case fires the workstream-file fact too. (verifier) (fixed)
- r12: `ledger-fields-with-no-rebuild` rests its partial-rebuild conclusion on
  the half of a self-contradicting file that the file itself denies
  (`orchestrate.md:554` against `:612-613`). Read against the rows, both
  summaries are loose: entry age gates the first rung, `seen=` gates the
  verdict. The conclusion survives; the contradiction is now a finding, and is
  arguably a better answer to the issue than the field classification.
  (verifier) (fixed)
- r13: `where-a-red-base-reading-goes` said the baseline grep "returns only"
  three categories. It returns 14 hits, four of them a different sense of the
  word. The conclusion survives; the word did not. (verifier) (fixed)
- r14: `no-ceiling-on-one-item` enumerated six knobs from a command that
  reaches three, with no command producing the list. Replaced with the output
  of a named command: 44 names. Counted twice — the reader and I disagreed by
  one, and the difference was the pattern's bare-prefix match, now stated.
  (verifier) (fixed)
- r15: All nine `## Verification` sections read "Pending". Nine nodes carrying
  roughly sixty findings would have reached `main` in breach of
  `.agents/docs/research/README.md`, "Verification is not optional". Filled,
  each claim marked, with the standing limit on every reported fleet number
  (the verifier declares no control-plane call — issue #267, planned as
  `docs/plans/verifier-cannot-read-the-plane.md`), so those are WEAK and say
  why. (verifier) (fixed)
- r16: Two Method greps assert zero hits for a string that each node's own text
  now contains, so the command does not reproduce in the tree the node lands
  in. Both pinned to `cb0028e` with that said in the finding. (verifier)
  (fixed)
- r17: Two `## Question` sections were compound against the README's "one
  sentence, answerable". Both reduced to one question, with the dependent
  halves moved to `## What would settle it`, where they already were.
  (verifier) (fixed)
- r18: Three quotations carried silent cuts presented as verbatim. Marked with
  `…`, and the one that mattered restored — the dropped half of
  `unsupervised.md:111` names the other cause that run ended. (verifier)
  (fixed)
- r19: The #296 fixture used the consumer orchestrator's actual branch name,
  taken from the issue. Opaque, but unnecessary — the fixture works with any
  name. Replaced. (verifier) (fixed)
- r20: `push-age-is-not-death` said no fleet-wide reading exists where the grep
  returns one hit, a comment saying the opposite. Named. (verifier) (fixed)
- r21: `first-copy-of-the-exit-rule`'s strongest claim rests on an observation
  of this session's own skills listing, which no second context can re-take.
  Marked WEAK in `## Verification` with that as the reason, not doubt.
  (verifier) (fixed)
- r22: `#303` should be a plan, not a node — one-line fix, `effort: low`, and
  the only open item is implementation, which `## Decide alone` already
  assigns. The reader also counted the precedent this branch cites: `605557b7`
  routed four of five issues to PLANS; this batch routed nine of nine to
  research. (verifier) (wontfix — the ask was a conversion to research nodes,
  and converting one unasked would make the batch inconsistent in a way
  canonical cannot see. The argument and the 4-of-5 ratio are now recorded in
  the node's own Consequence and in the pull request body, which is where the
  decision can be taken in one read.)
- r23: `#283` is half plan and this branch did not flag it: option 1 is a
  decided one-sentence deletion that the node itself calls the narrowest fix
  and rests its urgency on, beside a genuinely open question about a cost
  discriminator. Flagged in the node. (verifier) (wontfix as a split, same
  reason as r22; the flag is the deliverable.)
- r24: `## Echo` carries post-method content in four nodes, which weakens the
  one property the README gives that section. (verifier) (wontfix — the reader
  marked it a judgement call itself, the precedent node does the same, and each
  node carries an explicit "Written before the reads below" line in
  `## What would settle it`, which is where the protocol puts the
  anti-hindsight guarantee. Recorded rather than dropped because a reader who
  disagrees should find it argued, not absent.)

Clean on the independent read, worth recording because they were checked
rather than assumed: no invented number anywhere in the batch — every reported
figure traced to its issue clause by clause, including the three sessions'
`updated_at` and `cost_usd` in matching order; no consumer repository, plan
name, item name, pull request number or session id in any node; all nine
sections present and ordered in all nine; `research:` self-naming its stem;
every `graduates:` path on disk; no date in any `## Verification`; and every
`sed -n` range landing on the text its finding attributes to it, except r9.

## Blockers

None.

## Where to look

- `.agents/docs/research/README.md` — the nine sections, routing, and the
  no-date rule in `## Verification`.
- `docs/research/bash-guard-reads-prose-as-a-loop.md` — the consumer-report
  shape this follows, including how it carries measurements it could not take.
- `.agents/docs/consumer-repos.md`, `## Name no consumer` — what a citation
  may carry.

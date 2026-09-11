---
workstream: harness-agents-cut
status: in-progress
branch: claude/review-optimize-1g74te
pr: none
plan: harness-agents-cut
issue: none
session: https://claude.ai/code/session_01SqqhwxWTrXDj4t8bo2K9cU
agent: opus
updated: 2026-09-11
next: Spawn the verifier at opus on the full diff, record the round, then retire and open the pull request
---

## Goal

`.agents/harness/AGENTS.md` is loaded by every session, in every mode, at
every tier, before its first prompt — and it opens by citing ETH AGENTbench
for "long context file hurt agent, cost more". Cut it back toward the size
its own first line argues for, without losing a rule. Plan:
`docs/plans/harness-agents-cut.md`.

## Baseline, counted at claim time

`./joharness.sh context` on `origin/main` at `d599198`, 2026-09-11:

    CLAUDE.md                    399 bytes     56 words
    AGENTS.md                   2454 bytes    354 words
    .agents/harness/AGENTS.md  15882 bytes   2257 words
    instructions               18735 bytes   2667 words

Recounted the growth series with the command in `.agents/docs/caveman.md`
("What it costs, counted") rather than copying the plan's number, which the
plan asks for because the number moves — and it had: the plan cites 2129 on
2026-09-06, the file is 2257 today across 33 commits. 770 on 2026-08-23, so
2.9x in 19 days, not the 2.8x in 14 the plan was written against.

Acceptance is the `instructions` subtotal below 18735 bytes / 2667 words,
both numbers re-counted after the cut and written beside these.

**After the cut**, same command, same checkout, re-run after the LAST edit
(see r1 — the first set of these numbers was not):

    CLAUDE.md                    399 bytes     56 words
    AGENTS.md                   2454 bytes    354 words
    .agents/harness/AGENTS.md  14709 bytes   2048 words
    instructions               17562 bytes   2458 words

So `instructions` is 1173 bytes and 209 words lighter, all of it out of the
one file, paid by every session in every mode at every tier after it merges.
`ci`'s own context stage prints the delta without being asked.

The file is back under its 2026-09-06 size (2129) and roughly at 2026-09-05
(2080). It is NOT back to 770 — that would be a repeal, which the plan puts
out of scope.

## Decisions

- Supervised only, and this session qualifies: the file is protocol text
  (`./joharness.sh protocol-paths` lists `.agents/harness`), the mode is
  `supervised`, and the human is present. An unattended session must not
  claim this plan.

- **The cut is subtraction of DUPLICATED why, not compression of prose.**
  Checked before moving anything: for each candidate, is the fact already in
  the file that owns it? Six of nine already were. That makes this the file's
  own opening rule applied to itself ("Why-explanations live in
  `.agents/docs/`") and caveman.md's "State each fact once" — and it follows
  the precedent PR220 r2 set, which fixed the same shape "by subtraction:
  no longer restates the rule, it points at the output that carries it".
  The lever was LOCATION, as the plan demands; no sentence was caveman-squeezed
  to hit a number.

### Every rule moved, and where it is now findable

Nine edits. "already there" = verified present at that path BEFORE this diff,
so the edit is a pure delete of a second copy; "written" = this diff put it
there.

1. Background-command incident (2026-09-05 panel, 1h 17m) —
   `.agents/harness/pretool-bash-guard.sh` header, already there, with both
   offending commands verbatim and the `pgrep -f` self-match explained. KEPT
   in the Loop: the rule, the `pgrep` trap, the guard pointer, AND the
   ATTACHED/backstop sentence — PR215 r5 deliberately put that in both the
   comment and the Loop rule, so cutting it here would undo a recorded fix.
2. Retire accretion, "23 in one consumer repo, thirteen merges adding six and
   removing none" — `.agents/docs/handover/README.md`, **written** by this
   diff. It was the one candidate with no home. Its point (a literal reader
   takes "optional, human-only" as covering the files too) is now stated where
   the protocol lives, and the Loop's wording says outright that the files are
   NOT covered by it.
3. Finish ordering, "one session, eight pull requests, three deferred" —
   already there, twice: `.agents/docs/handover/README.md` and
   `.agents/docs/feedback.md`. Deleted as a third copy.
4. `ci`-versus-`finish` two-strengths reasoning — `joharness.sh:fin_strength`,
   already there, and the Loop already named that function. Rule kept, reason
   points.
5. Heartbeat measurement, "5 of 119 gaps exceed three hours, longest 32.2h and
   24.0h" — `.agents/docs/unsupervised.md`, already there. Deleted as a
   second copy; the pointer stays.
6. Harness-upkeep routes (`update.yml` / subagent / own session) —
   `.agents/docs/consumer-repos.md`, already there and already IN preference
   order, which is what the Loop line promises. Deleted as a second copy.
7. Review depth by tier (haiku one pass / sonnet `/code-review` high / opus
   adversarial) — `.agents/docs/agent-selection.md`, already there. Safe
   because the depth also reaches the session from the TOOL:
   `./joharness.sh review` prints this branch's depth, and the Loop now says
   so rather than restating the table.
8. `JOHARNESS_CHECKS=local` mechanics (what it refuses, what it cannot cover)
   — `joharness.conf`, already there, in the comment on the key that sets it.
   Session start still announces the mode; the Loop keeps what the switch
   REPLACES, which is the part that changes a merge decision.
9. Curate DUE condition and the command's own job description —
   `./joharness.sh drain` computes and prints the condition, and
   `.claude/commands/curate.md` IS the role. Kept: `curate : DUE` outranks the
   queue, `/curate` is the command, one in flight is somebody else's, and
   "not inventing work".

Nothing was repealed. Every sentence removed is reachable from a pointer the
file still carries, and six were reachable already.

## Rejected

(nothing yet)

## Review

Depth: opus adversarial (`./joharness.sh review`), plus
`.claude/agents/verifier.md` at opus — one reader that did not write the diff.
It confirmed the thing the plan most feared did NOT happen: it checked all
nine moves independently and found no rule gone, no repeal wearing a move's
clothes, and no past fix undone. Everything below is what it found instead.

- r1: (verifier) every after-cut number in the commit message and this file
  was stale by 41 bytes / 8 words — measured, then one more wording edit
  landed, and the command was never re-run. Recorded in backticks as literal
  `ci` output that `ci` did not produce. The acceptance gate still passed, so
  nothing would have caught it. This is Loop step 5's own rule — "Trust
  counted numbers, never written numbers" — broken inside the diff that
  relocates step 5's neighbours, by the session that had just re-counted the
  baseline rather than copying the plan's. (fixed — re-run after the last
  edit: 14709/2048 and 17562/2458; the `.agents/docs` and `docs/handover`
  edits are outside the loaded chain, so these cannot drift again)
- r2: (verifier) the cut ADDED a duplicate in a diff whose thesis is
  subtracting duplicates: the new clause "`./joharness.sh review` prints THIS
  branch's" restated line 97, four lines below and untouched, which already
  said it. Same shape PR220 r2 recorded. (fixed — the depth table needed no
  replacement text at all; the pointer alone stands, and the file is smaller
  than the first attempt)
- r3: (verifier) one removed why-sentence had no landing site and was missing
  from this file's nine-move list: "a gate that fails for somebody else's
  omission is one sessions route around". The rule survived but the new
  pointer named `fin_strength`, whose comment explains the two strengths, NOT
  the inherited-file carve-out — that reasoning is in `fin_gate`, which
  nothing pointed at. Findable only by a session that already knew to look:
  the plan's Trap, exactly. PR199 r1 cites the same sentence as load-bearing.
  (fixed — sentence restored; it was a repeal, not a move, and 12 words is
  the right price)
- r4: (verifier) the new pointer called the landing site a "table"; the depth
  recipes are a nested bullet list, so a literal reader searching for a table
  concludes the pointer is stale. (fixed — resolved by r2's fix, which drops
  the added clause entirely)
- r5: (verifier) this diff wrote a measured number into
  `.agents/docs/handover/README.md` with no command and no date, one file from
  the rule demanding both, and beside a neighbour that shows the house form.
  PR215 r8 is the precedent. (fixed — not by inventing a producer: the number
  arrived unsourced from `AGENTS.md` and is not re-countable from this repo,
  so it now says so and is marked an anecdote whose SHAPE is the point)
- r6: (verifier) moving the upkeep routes orphaned a referent — "the session
  mid-plan reviews the resulting pull request" lost the thing that results.
  (fixed — "A sync route opens a pull request; the session mid-plan reviews it")
- r7: (verifier) "one sentence up" is four sentences up. Inherited from the
  old text, but the cut promoted the phrase from decoration to the corrective
  assertion itself. (fixed — "above", which is true at any distance)
- r8: (verifier) an unreflowed replacement left `   Merge-commit` alone on a
  line, in the file every session reads. (fixed)
- r9: (verifier, reasoned) `joharness.conf` does not sync and its seed writes
  only when the file is ABSENT, so a consumer whose conf predates that comment
  block never gets it, while the `AGENTS.md` sentence carrying those two facts
  is now gone. Verified the text is in both canonical conf and the bootstrap
  seed; could not reproduce against a real old consumer. (wontfix here —
  fixing it means changing what the seed does to an existing file, which is
  `.agents/scripts/` and outside this plan's scope and its `scope:` line.
  Recorded so the next session touching the seed has the reason in hand)
- r10: (verifier, reasoned, low) the counter-in-the-loop spelling of a bounded
  wait now reaches a session only through the guard's deny, after it has been
  refused. Verified `deny()` does print both spellings. (wontfix — the deny is
  the teaching moment by design, and the alternative is paying for the second
  spelling in every session that never types the first)

Clean on: all nine landing sites verified present, six of them on `origin/main`
before this diff; `./joharness.sh review` really does print the depth, and
`drain` really does print the DUE reason, so r2's and the curate cut's
premises hold; every referenced path resolves in a CONSUMER tree; both new
relative links resolve from `.agents/harness/`; no glossary-contested spelling;
no past fix undone.

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md` — the file. Its first line is the argument.
- `.agents/docs/caveman.md`, "Where it applies" and "What it costs,
  counted" — the rule served, and how to recount.
- `joharness.sh:ctx_report` — the instrument. Out of scope to change.

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

**After the cut**, same command, same checkout:

    CLAUDE.md                    399 bytes     56 words
    AGENTS.md                   2454 bytes    354 words
    .agents/harness/AGENTS.md  14651 bytes   2031 words
    instructions               17504 bytes   2441 words

So `instructions` is 1231 bytes and 226 words lighter, all of it out of the
one file, paid by every session in every mode at every tier after it merges.
`ci`'s own context stage prints that delta without being asked:
`this branch, to the chain: -1231 bytes, -226 words`.

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

(pending — step 5)

## Blockers

None.

## Where to look

- `.agents/harness/AGENTS.md` — the file. Its first line is the argument.
- `.agents/docs/caveman.md`, "Where it applies" and "What it costs,
  counted" — the rule served, and how to recount.
- `joharness.sh:ctx_report` — the instrument. Out of scope to change.

---
plan: narrower-human-remainder
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: .claude/commands/clerk.md, .agents/docs/manage-reference.md, .agents/docs/plans/TEMPLATE.md, .agents/docs/orchestrated.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

A clerk NARROWER verdict plans the part of an issue that holds. When the rest
needs a human decision, nothing tells the human: NARROWER writes a comment
only, with no `human-review` label and no numbered options. Every later clerk
pass skips the issue, because its newest counting comment is the clerk's own
verdict (`clerk.md` §2: "the next move is a human's"). Once the plan's pull
request merges, the issue either closes with the remainder unplanned (the
§ Plan issue rule says `Closes #N` when no other plan names it), or it stays
open with nobody holding it. Issue #597 shows both: its plan
(`human-half-order-and-park-pr`) was the only plan naming it, so the rule
said `Closes`. Its manager wrote `Refs #597` against the rule to keep gap 2
alive, and gap 2 then sat open, never shown to a human, until a human closed
the issue by hand. Make the remainder visible to the human, and make
`Closes` or `Refs` follow from the plan itself.

## Scope

- `.claude/commands/clerk.md` §3, **NARROWER**: the comment sorts each part
  that is not planned into one of two kinds.
  - Does not hold: give the evidence, as DOES NOT HOLD does.
  - Needs a human (the HUMAN reasons): name the question with 2 to 4 numbered
    options, `(recommended)` on one, and the same closing lines as a HUMAN
    comment. After the comment, apply `human-review` to the issue (for
    visibility only; the manager does not read it).
  - When any part needs a human, the plan carries a `## Issue remainder`
    section: one line per such part, naming the question. A plan without the
    section left no human remainder.
- `.claude/commands/clerk.md` §2, **A NUMBERED ANSWER**: a number selects an
  option of the newest `clerk: HUMAN` **or `clerk: NARROWER`** comment that
  carries numbered options.
- `.claude/commands/clerk.md`, the "One plan per issue" paragraph and the
  `## Never` carve-out: restate the `Closes`/`Refs` rule below, and add
  NARROWER to the verdicts that apply `human-review`.
- `.agents/docs/manage-reference.md` § Plan issue: when the plan has a
  `## Issue remainder` section, the body says `Refs #N`, never `Closes #N`.
  Otherwise the current rule stands. The rule reads the plan file, not the
  issue's labels, because a label can change while the plan is queued, and
  `manage.md` §3 also applies `human-review` on any block.
- `.agents/docs/plans/TEMPLATE.md`, the `issue` comment: name the
  `## Issue remainder` exception.
- `.agents/docs/orchestrated.md`, Bounds, `human-review` label: add the
  clerk's NARROWER verdict to the list of who applies it.
- `.agents/harness/selftest/orchestrated.sh`: pin the new rules by text, next
  to the clerk pins after the second `clerktext=` assignment and the
  `$mgrreftext` pins. Pin the NARROWER label, the numbered answer covering
  NARROWER, and `## Issue remainder` giving `Refs`. Each `expect` must fail
  against today's text.

## Assumptions

- A1: NARROWER today applies no label and gives no options. Evidence: `grep -n -A2 'NARROWER' .claude/commands/clerk.md`. Confidence: high.
- A2: the §2 skip rule skips an issue whose newest counting comment is the clerk's own verdict, whatever that verdict is. Evidence: `grep -n 'NEWEST counting comment' .claude/commands/clerk.md`. Confidence: high.
- A3: the numbered-answer rule names `clerk: HUMAN` only. Evidence: `grep -n -A6 'A NUMBERED ANSWER' .claude/commands/clerk.md`. Confidence: high.
- A4: `orchestrated.sh` reads `clerk.md` and `manage-reference.md` text into `$clerktext` and `$mgrreftext`. Evidence: `grep -n 'clerktext=\|mgrreftext=' .agents/harness/selftest/orchestrated.sh`. Confidence: high.
- A5: no `joharness.sh` reader parses plan body sections by name in a way a new `## Issue remainder` heading would break. Evidence: `./joharness.sh ci` on a plan carrying the heading. Confidence: medium.

## Out of scope

- Any `joharness.sh` change: no new frontmatter key, and no `clerk` report
  line for issues whose plans all retired.
- Re-reading issues whose plans retired with only `Refs` (a later plan, if
  wanted).
- Changing the §2 skip rule, the HUMAN verdict, or the DOES NOT HOLD verdict.
- Editing any issue.

## Acceptance

- `./joharness.sh ci`: prints `ci: pass`.
- `./joharness.sh verify`: prints `0 failed`.
- The new expects fail without the doc edits. Run `git stash push --
  .claude/commands/clerk.md .agents/docs/manage-reference.md
  .agents/docs/orchestrated.md .agents/docs/plans/TEMPLATE.md`, then
  `.agents/harness/selftest.sh`. Each new expect line prints as failed. Then
  run `git stash pop`.
- `grep -n 'human-review' .claude/commands/clerk.md` shows NARROWER among the
  lines that apply it.
- Consumer side, after its next sync:
  `grep -n 'Issue remainder' .agents/docs/manage-reference.md` matches in the
  consumer checkout.

## Where to look

- `.claude/commands/clerk.md`: §2 **A NUMBERED ANSWER**, §3 **NARROWER** and
  **HUMAN**, the "One plan per issue" paragraph, and `## Never`.
- `.agents/docs/manage-reference.md` § Plan issue.
- `.agents/docs/plans/TEMPLATE.md`, the `issue` comment.
- `.agents/docs/orchestrated.md`, Bounds.
- `.agents/harness/selftest/orchestrated.sh`: the clerk pins after the
  second `clerktext=` assignment.

## Traps

- `.github`, `joharness.conf` and `.claude/settings.json` are core paths:
  never touch them.
- A test for a fix must FAIL without it.
- NEVER skip, disable or quarantine a test to get green.
- The tree holds still while your verifier runs: stash nothing during it.

---
plan: narrower-human-remainder
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: .claude/commands/clerk.md, .agents/docs/manage-reference.md, .agents/harness/selftest/orchestrated.sh
---

## Goal

A clerk NARROWER verdict plans the part of an issue that holds. When the rest
needs a human decision, nothing tells the human: NARROWER writes a comment
only, with no `human-review` label and no numbered options. Every later clerk
pass skips the issue, because its newest counting comment is the clerk's own
verdict (`clerk.md` §2: "the next move is a human's"). The plan's pull request
then retires, and the issue drops off `planned` with nobody holding the
remainder. Issue #597 sat open this way: gap 1 was built in PR #600
(`Refs #597`), and gap 2 was never shown to a human. Make the remainder
visible, and make the manager's `Closes`/`Refs` choice follow from it.

## Scope

- `.claude/commands/clerk.md` §3, **NARROWER**: the comment sorts each part
  that is not planned into one of two kinds.
  - Does not hold: give the evidence, as DOES NOT HOLD does.
  - Needs a human (the HUMAN reasons): name the question with 2 to 4 numbered
    options, `(recommended)` on one, and the same reply instructions as a
    HUMAN comment. After the comment, apply `human-review` to the issue.
  - The `Never` list's `human-review` carve-out names NARROWER as well as
    HUMAN.
- `.agents/docs/manage-reference.md` § Plan issue: the plan's issue carries
  `human-review` when the pull request opens (the same one `get_labels` read
  that already checks `scout`) = `Refs #N`, never `Closes #N`, whatever other
  plans name it. Otherwise the current rule stands.
- `.agents/harness/selftest/orchestrated.sh`: pin both rules by text, as the
  existing `clerk: HOLDS — plan` and `post ONE comment on that issue` checks
  do. Each `expect` must fail against today's text.

## Assumptions

- A1: NARROWER today applies no label and gives no options. Evidence: `grep -n -A2 'NARROWER' .claude/commands/clerk.md`. Confidence: high.
- A2: the §2 skip rule skips an issue whose newest counting comment is the clerk's own verdict, whatever that verdict is. Evidence: `grep -n 'NEWEST counting comment' .claude/commands/clerk.md`. Confidence: high.
- A3: § Plan issue already reads the issue's labels once, for `scout`. Evidence: `grep -n 'get_labels' .agents/docs/manage-reference.md`. Confidence: high.
- A4: `orchestrated.sh` already reads `clerk.md` and `manage-reference.md` text into `$clerktext` and `$mgrreftext`. Evidence: `grep -n 'clerktext=\|mgrreftext=' .agents/harness/selftest/orchestrated.sh`. Confidence: medium.

## Out of scope

- Any `joharness.sh` change: no new frontmatter key, and no `clerk` report
  line for issues whose plans all retired.
- Re-reading issues whose plans retired with only `Refs` (a later plan, if
  wanted).
- Changing the §2 skip rule, the HUMAN verdict, or the DOES NOT HOLD verdict.
- Editing issue #597 (closed) or any other issue.

## Acceptance

- `./joharness.sh ci`: prints `ci: pass`.
- `./joharness.sh verify`: prints `0 failed`.
- The new `orchestrated.sh` expects fail with the `clerk.md` and
  `manage-reference.md` edits reverted (`git stash` those two files, then run
  the selftest topic).
- `grep -n 'human-review' .claude/commands/clerk.md` shows NARROWER among the
  lines that apply it.

## Where to look

- `.claude/commands/clerk.md` §3, the **NARROWER** and **HUMAN** bullets, and
  the `## Never` carve-out.
- `.agents/docs/manage-reference.md` § Plan issue.
- `.agents/harness/selftest/orchestrated.sh`: the block that checks
  `$clerktext`.

## Traps

- `.github`, `joharness.conf` and `.claude/settings.json` are core paths:
  never touch them.
- A test for a fix must FAIL without it.
- NEVER skip, disable or quarantine a test to get green.

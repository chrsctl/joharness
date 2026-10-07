---
plan: release-reds-the-branch-it-releases
urgency: normal
agent: sonnet
effort: medium
needs: abandoned-reaches-every-reader
scope: .claude/commands/janitor.md, .agents/harness/selftest/janitor.sh
---

## Goal

#279's first defect, which the issue calls "the one that matters and the least
obvious". Writing `status: abandoned` into a claim reds `ci` on that claim's own
branch, because the branch carries an older `joharness.sh` whose enum predates
the word.

Measured 2026-10-07 across every abandoned branch on `origin`, with
`git show "origin/$b:joharness.sh" | grep -oE 'lint_enum "\$rel" status[^;]*'`:
**6 of 8** carry an enum without `abandoned`. One knows it; one carries no
`joharness.sh` at all, so nothing lints there. A reviewer of PR294 checked only
the branch that knows the word and reasonably concluded the defect was inert —
it bites on six others.

The cost is specific: the Loop tells a returning session to run
`./joharness.sh ci` at step 5, before touching anything. That session gets
`DEAD docs/handover/<file>.md: status 'abandoned' not one of: in-progress
blocked review done` and `ci: FAIL` on a line it did not write. It will either
debug the harness or stop trusting the gate.

A mitigation already exists and is mandatory: those branches are 1300+ commits
behind and must reconcile with `main` before merging, which brings the new enum.
**Nothing says so at the moment the red appears.** That is the whole gap.

## Scope

The issue names three options. Take the third — it is the one it calls "the
cheap honest one", and it is the only one that does not weaken a lint:

- `.claude/commands/janitor.md` §3 — the release note's required contents. Add
  one line to what the note must carry: that `ci` on this branch will red on the
  status word until the branch reconciles with its base, and that the reconcile
  is what fixes it. The note is already where a returning session looks, and it
  is already required to explain the release.
- `.agents/harness/selftest/janitor.sh` — one case asserting the release note
  carries that sentence, so a future rewrite of the role cannot drop it
  silently.

## Out of scope

- **Weakening `lint_enum`.** Option 1 in the issue — tolerate an unknown status
  when the branch's base is older than the value — makes a correctness gate
  conditional on history, and a gate that sometimes does not fire is the kind
  sessions learn to ignore. Named here so it is a decision, not an omission.
- **Having the release carry the reconcile.** Option 2. A janitor commits ONE
  commit to another session's branch and may not rewrite anything else there
  (`.claude/commands/janitor.md` `## Never`); merging `main` into somebody
  else's branch is a far larger act than the release it accompanies.
- **Anything in `joharness.sh`.** This plan changes a role's required words and
  one test. If it starts editing the entrypoint, the chosen option was the
  wrong one.
- **#279's defects 2, 3 and 5** — `docs/plans/abandoned-reaches-every-reader.md`.

## Acceptance

1. `./joharness.sh ci` → `ci: pass`.
2. `bash .agents/harness/selftest.sh` → `0 failed`, pass count above the merge
   base's.
3. The new case fails without the change: revert the `janitor.md` line, run the
   topic, see it red, restore. A case green both ways pins nothing.
4. `./joharness.sh mutate` on the asserted sentence reds that case and leaves
   the rest of the topic green, off a green baseline.
5. Read back from a reader's seat: `git show
   origin/<an-abandoned-branch>:joharness.sh | grep -c abandoned` is still 0
   after this change — this plan does not pretend to fix the enum, and the
   workstream file says so.
6. Consumer-side, because `.claude/commands/janitor.md` SHIPS (`./joharness.sh
   ci` prints it under `== ship scope`): in a consumer that has synced this
   change, a sweep's release note carries the sentence, and a session that then
   runs `./joharness.sh ci` on the released branch sees the red WITH the note
   explaining it. A bar met only in the canonical repo is met in the one repo
   that was never the risk — the consumer is where a returning session meets
   this red. State whether that check was run or only specified.

## Where to look

- `.claude/commands/janitor.md` — §3 Release, the note's required contents.
- `joharness.sh:lint_enum` — read it to confirm the red's exact wording before
  quoting it; do not change it.
- `.agents/harness/selftest/janitor.sh` — the release-note cases already there.

## Traps

- `.claude/commands/` is protocol text. A sweep may not edit it
  (`.claude/commands/janitor.md` `## Never`), and under unattended mode no
  session may. This plan is for a supervised session.
- The red is REAL, not spurious: the branch's enum genuinely lacks the word.
  The sentence must say the reconcile fixes it, never that the red is wrong.
- Never report a count without the command that re-counts it.
- `needs:` names the sibling plan because this one's sentence should describe a
  world where the other readers already honour the word; landing this first
  would document a half-state.

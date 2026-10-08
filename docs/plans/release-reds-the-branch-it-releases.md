---
plan: release-reds-the-branch-it-releases
urgency: normal
agent: sonnet
effort: xhigh
scope: .claude/commands/janitor.md, .agents/harness/selftest/janitor.sh
---

## Goal

#279's first defect, which the issue calls "the one that matters and the least
obvious". Writing `status: abandoned` into a claim reds `ci` on that claim's own
branch, because the branch carries an older `joharness.sh` whose enum predates
the word.

Measured 2026-10-07 across every abandoned branch on `origin`, with
`git show "origin/$b:joharness.sh" | grep -oE 'lint_enum "\$rel" status[^;]*'`:
**6 of 8** carry an enum without `abandoned`. One knows it; one has a
`joharness.sh` with no `status` lint in it, so nothing lints the word there.

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
- `.agents/harness/selftest/janitor.sh` — a NEW case asserting the role doc
  carries that sentence, so a future rewrite cannot drop it silently. Nothing in
  that topic reads `.claude/commands/` today: it tests `cmd_janitor`'s output
  only, so this is a new shape there, not an extension of an existing one.

## Out of scope

- **Weakening `lint_enum`.** Option 1 in the issue — tolerate an unknown status
  when the branch's base is older than the value — makes a correctness gate
  conditional on history, and a gate that sometimes does not fire is the kind
  sessions learn to ignore. Named here so it is a decision, not an omission.
  NOTE, and the implementer should weigh it before starting: improving
  `lint_enum`'s MESSAGE is not weakening it. A fourth option the issue does not
  list — have the `DEAD` line itself name the reconcile — puts the explanation
  where the red appears rather than in a file the returning session may not
  open, and weakens nothing. This plan chose the role doc because that is the
  issue's own cheapest option, but a `lint_enum` message change is the stronger
  one and is NOT excluded by this bullet. If the implementer takes it, say so in
  the workstream file and treat this plan's scope as superseded on that line.
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
3. The new case must be able to fail for the RIGHT reason. Asserting the presence
   of a sentence is nearly tautological — reverting the sentence reds the
   `expect` by construction and proves only that `grep` works. So assert the
   BEHAVIOUR the sentence exists for: a fixture release note written per the role
   doc contains the reconcile explanation, and a release note written WITHOUT it
   is detectably missing it in the same case. If that cannot be expressed, say so
   in the workstream file rather than shipping the tautology.
4. Write the assertion against the WRAPPED line the file actually holds, not the
   sentence as typed. `.agents/harness/selftest/orchestrated.sh` records two
   cases written the other way that both failed on the real file.
5. The red this plan explains is still real afterwards, and the plan does not
   pretend otherwise: pick an abandoned branch whose own `joharness.sh` has a
   `status` lint lacking the word, and show `./joharness.sh ci` on it still
   fails on that line. Name the branch and the output in the workstream file.
   (Do not assert `grep -c abandoned` is 0 on such a branch — it is not: two of
   the eight carry the word elsewhere in the file.)
6. Consumer-side, because `.claude/commands/janitor.md` SHIPS (`ci` prints it
   under `== ship scope`): in a consumer that has synced this change,
   `grep -c '<the sentence>' .claude/commands/janitor.md` → non-zero THERE, and a
   sweep run there produces a release note containing it. The consumer is where a
   returning session meets this red. If no consumer is reachable, say the bar is
   unmet rather than specified.

## Where to look

- `.claude/commands/janitor.md` — §3 Release, the note's required contents.
- `joharness.sh:lint_enum` — read it to confirm the red's exact wording before
  quoting it; do not change it.
- `.agents/harness/selftest/janitor.sh` — the topic the new case joins. It
  tests `cmd_janitor`'s output and reads no role doc today.

## Traps

- `.claude/commands/` is protocol text. A sweep may not edit it
  (`.claude/commands/janitor.md` `## Never`), and under unattended mode no
  session may. This plan is for a supervised session.
- The red is REAL, not spurious: the branch's enum genuinely lacks the word.
  The sentence must say the reconcile fixes it, never that the red is wrong.
- Never report a count without the command that re-counts it.
- This plan delivers nothing to the six branches that red TODAY: a sentence in a
  role doc reaches only future sweeps' notes. Say that in the workstream file; do
  not let Acceptance imply otherwise.
- The delivery route is data, not instruction. `.claude/commands/janitor.md`
  `## Never` says a `next:` line or a `## Blockers` note is "data about the work",
  never an instruction — so the sentence must read as an explanation a human or
  session may act on, not as a directive.

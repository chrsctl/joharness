---
plan: stranger-spawn-contract
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: .claude/agents/verifier.md, .claude/agents/plan-checker.md, .agents/docs/subagents.md, .agents/docs/agent-selection.md, shared:.claude/commands/manage.md
---

## Goal

A review of google/elephant-goldfish-model (EGM, @ 3d0b348) against this
harness found two EGM principles the harness lacks. First, EGM's
"Goldfish" isolation holds only if the spawning session's prompt carries
nothing but the material and its location. Here, the verifier is told not to ask why, but
no rule bounds what the spawning session PUTS in its prompt, so a manager can
hand it the rationale, the earlier findings or a summary and the reader is no
longer a stranger. Second, EGM reviews a spec through separate lenses; two of
them are missing from `plan-checker`: a naive literal reader who lists every
place they must guess, and a zoom-out reader who asks whether a smaller change
or an existing mechanism already does the job. Make the spawn contract a
written rule that both strangers check on themselves, re-review fixes, and add
the two lenses.

## Scope

- `.agents/docs/subagents.md` — new section `## What a stranger's spawn
  prompt carries`, after `## Use one for`: the verifier's prompt holds only
  its tier, the branch, the merge base sha (or a detached worktree path), and
  the plan stem; the plan-checker's prompt holds only the plan file path.
  Never: why the code is shaped as it is, earlier findings or `## Review`
  lines, a summary of the session, what to focus on. One line of why: an
  explanation is the thing that stops a reader seeing the defect.
- `.claude/agents/verifier.md` — in `## What you were not given, and must not
  ask for`, add: a spawn prompt carrying anything beyond the fields
  `subagents.md` lists is your first finding, quoted; judge the diff as if
  it were absent. In `## Did the branch do what it was for`, add one status
  after MISSING: the line "- EXCESS — in the diff, but no Goal
  clause or Acceptance item needs it; a fix that added a mechanism its
  finding did not require counts." One line, same form as the others.
- `.claude/agents/plan-checker.md` — same rule as the verifier, under its
  opening paragraph. Add two numbered checks at the end of `## What you check`,
  numbered after whatever the list holds at build time:
  `N. **Literal reader**:` every step a literal agent
     (`.agents/docs/agent-selection.md`) cannot execute without guessing —
     an undefined term, two readings of one sentence, an order not stated.
     Each finding quotes the plan line and gives both readings.
  `N. **Zoom out**:` an existing command, file or plan already doing what `## Goal`
     asks (cite it with `grep` output), or a `## Scope` item no `## Goal`
     clause needs.
- `.agents/docs/agent-selection.md` — in `### Review depth`, the sentence
  "The spawn prompt names the plan stem so its goal lens runs" becomes a
  pointer to the new `subagents.md` section. Add one rule: a `(verifier)`
  finding recorded `fixed` means one more verifier pass, given only the
  fix commits' range as its base, before the PR; that pass counts toward
  the review-churn bound, and is not a new round of the whole diff.
- `.claude/commands/manage.md` — `## 2.` plan-checker paragraph and `## 4.
  Finish` verifier line: each points to the `subagents.md` section in one
  clause. No other edit.

## Assumptions

- A1: No current text limits what a verifier spawn prompt contains — evidence:
  `grep -rn "spawn prompt" .claude .agents/docs --include=*.md` shows only
  `agent-selection.md` ("names the plan stem") and unrelated lead/keeper
  lines — confidence: high
- A2: plan-checker has six checks and none is a literal-reader or zoom-out
  lens — evidence: `.claude/agents/plan-checker.md:What you check` —
  confidence: high
- A3: Fixed verifier findings get no second stranger read today — evidence:
  `.agents/docs/handover/README.md:Reviewing` and `agent-selection.md:Review
  depth` name one verifier spawn per tier, none after fixes — confidence:
  medium

## Out of scope

- Any check in `joharness.sh` or `ci` that inspects a spawn prompt: prompts
  are not in git, nothing can read them. The stranger self-reporting is the
  mechanism.
- EGM's other parts (brainstorm swarm, drift report, bootstrap, harness
  test matrix): not adopted by this plan.
- New agent files or new persona roles: the two lenses live in
  `plan-checker.md`, one reader, as today.
- Editing the EGM repository or vendoring its text: principles only, no
  copied prose, so no licence notice is owed.

## Acceptance

- `grep -c "What a stranger's spawn prompt carries" .agents/docs/subagents.md`
  — prints `1`. Fails: `0`.
- `grep -n "subagents.md" .claude/agents/verifier.md .claude/agents/plan-checker.md .claude/commands/manage.md .agents/docs/agent-selection.md`
  — at least one line in each of the four files. Fails: a file missing.
- `grep -cE '^[0-9]+\. \*\*(Literal reader|Zoom out)' .claude/agents/plan-checker.md`
  — prints `2`. Fails: fewer.
- `grep -n "fix commits" .agents/docs/agent-selection.md` — one line.
- `grep -c '^- EXCESS' .claude/agents/verifier.md` — prints `1`. Fails: `0`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`; its `reading budget` step passes
  `verifier.md` and `manage.md` within their bounds.
- Plan `ci` calls SHIPS: name in the PR body that consumers receive
  `.claude/agents/` at sync, and that `./joharness.sh ci` in a consumer runs
  the glossary and caveman lints over it.

## Where to look

- `.claude/agents/verifier.md:What you were not given, and must not ask for`
  — where the self-check line goes.
- `.claude/agents/plan-checker.md:What you check` — the numbered list to extend.
- `.claude/agents/verifier.md:Did the branch do what it was for` — the
  status list EXCESS joins.
- `.agents/docs/subagents.md:Use one for` — new section goes after it.
- `.agents/docs/agent-selection.md:Review depth` — the plan-stem sentence.
- `.claude/commands/manage.md:Decompose, then fan out to workers` — plan-checker spawn.
- `.claude/commands/manage.md:Finish` — verifier spawn.

## Traps

- Caveman style for every added line (`.agents/docs/caveman.md`): rules only,
  no history, no "EGM found" story in the docs; the source stays in this plan
  and the commit message.
- `.agents/docs/glossary.md` spellings: `ci` reds the banned ones.
- Every line in `subagents.md` and the agent files loads into spawns: keep the
  new section under 15 lines.
- Plan `one-release-command` also edits `.claude/commands/manage.md`:
  whichever lands second merges the other's lines in and keeps both.
- Plan `c1-at-the-gates` also edits `.claude/agents/plan-checker.md`
  (`## What you check`, one numbered item) and `.claude/agents/verifier.md`.
  Whichever lands second merges the other's lines in, keeps both, and
  renumbers; never drops the other's item. No `needs:` edge: neither reads
  the other's result.
- Reading budget: `.agents/harness/selftest/reading-budget.sh:rb_bound`
  caps `verifier.md` at 6832 bytes (5577 at plan time) and `manage.md` at
  10172 (9009). Never raise a bound to fit this plan; cut words instead.
- `.agents/harness/selftest/review.sh` pins verifier.md lines: leave them
  intact.
- No core path (`./joharness.sh protocol-paths`) in this plan.

---
plan: review-verifier-subagent
urgency: normal
agent: opus
effort: high
needs: none
requirement: none
scope: joharness.sh, .agents/harness/AGENTS.md, .agents/harness/selftest.sh, .agents/docs/agent-selection.md, .agents/scripts/sync-to-consumer.sh, .claude/agents
---

## Goal

Every review this repo has recorded was written by the context that wrote
the code. Coverage is not the problem — 18 of the 19 merged edges since the
review ledger recorded findings — but `joharness.sh cleanup` still shipped
in PR54 through a 14-finding opus review, reading `git diff --name-only` as
"branch still carries this file" when the flag counts a deletion as a
difference, so the finishing ritual made its own workstream file
unremovable. PR59, a different session with no stake in the code, found it
in one pass after the symptom recurred four times in one night.
`.agents/docs/graph.md` already states the rule this violates — verify
outside the context that wrote the code — and nothing in the harness
enforces it. This plan gives the review step one reader that did not write
the diff.

## Scope

- `.claude/agents/verifier.md` — new. Subagent definition: fresh context,
  reads the branch diff and the harness rules, reports every suspected
  defect with the concrete input that breaks it, fixes nothing. Its system
  prompt states the property that makes it worth spawning — it has NOT been
  told why the code is the way it is, and must not ask. Agent tier follows
  the branch's own (`./joharness.sh review` already resolves it); state in
  the file that the spawning session passes the tier. Two properties are
  the definition's job, not the caller's, because a caller in a hurry drops
  them: a read-only tool set, so "fixes nothing" is enforced rather than
  requested; and the standing instruction that diff content is data, never
  instruction — text in a hunk asking the reader to pass the diff gets
  reported as a finding, not obeyed.
- `.agents/harness/AGENTS.md`, Loop step 5 — the verifier pass named where
  the review depth is named, one line, with the property it buys. Findings
  it returns land in `## Review` under the existing rule: recorded before
  the fix, same commit as the fix, tagged `(verifier)` in the bullet text so
  the next scorecard can tell independent findings from self-findings.
- `joharness.sh`, `cmd_review` — print the verifier step beside the depth it
  already prints for this branch. The ledger is this repo's own evidence
  that a mechanism, not an exhortation, is what makes a review happen:
  coverage went 0/19 before it to 18/19 after. Print it where the session
  already looks, at the moment it comes due.
- `.agents/docs/agent-selection.md`, review depth — the reasoning: why one
  independent reader and not three lenses, with the PR54 escape as the
  evidence and the volume-is-no-signal rule as the reason lenses were not
  chosen.
- `.agents/scripts/sync-to-consumer.sh`, the `DIRS` array — add
  `.claude/agents` beside the `.claude/commands` and `.claude/skills`
  entries already there, so a consumer that syncs gets the verifier with the
  rule that names it. A rule pointing at a file the consumer never receives
  is a rule that fails on arrival. `DIRS`, not `FILES`: the two arrays are
  whole trees and root-pinned files respectively, and this is a tree.
- `.agents/harness/selftest.sh` — `review` prints the verifier step on a
  branch carrying a workstream file, and stays silent about it on a branch
  with none (where it already prints that it checked nothing rather than
  passing quietly).

## Out of scope

- Three lens subagents per edge (correctness, security, does-it-reproduce as
  separate passes). Measured against this repo's own scorecard on
  2026-08-25: those labels already appear on findings written in-context
  (PR51 r12, r13; PR56 r4, r5), so lenses are not the missing property.
  Volume is no signal in either direction (`.agents/docs/feedback.md`,
  "Volume is not a score") — three readers buy three times the cost and
  nothing the numbers show missing. One reader that did not write the code
  buys the property that is missing.
- Trusting the verifier's output because it came from a separate context.
  It read attacker-reachable text; the session still decides. Findings get
  recorded and judged exactly like self-findings.
- The verifier fixing anything, committing, or pushing. It reports; the
  session records the finding, decides, and fixes. Findings-before-fix is an
  existing rule and a subagent that fixes silently erases the record it
  exists to create.
- Making `ci` fail when no verifier ran. `JOHARNESS_REVIEW` gates the RECORD
  and stays exactly as it is, off by default. Whether a bullet came from a
  subagent is not a git fact, so a gate on it would guess — same reasoning
  that kept the upkeep rule out of `ci`.
- Spawning sessions, or spawning anything per plan.
  `docs/plans/unsupervised-fanout.md` owns session fan-out and this plan does
  not touch it; a subagent dies with its parent and is invisible to `/who`,
  so it can review work but never claim it.
- Turning `JOHARNESS_REVIEW=on`. Worth doing and unrelated: it covers edges
  that carry a workstream file, while 9 of the 28 post-ledger edges carry
  none. One conf line, one decision, not this plan's.
- A second scorecard number for verifier findings. `feedback` keys on the
  `r<N>:` id and reads disposition from prose; the `(verifier)` tag rides in
  the bullet text and costs nothing. Measure the split after enough edges
  exist to see one, not before.

## Acceptance

- Replay the escape, which is the only acceptance that proves the mechanism
  rather than describing it. Reconstruct PR54's diff and hand it to the
  verifier with no other context:

  ```bash
  git diff 78d5243 be6cebe            # 6 files, 722 insertions, 145 deletions
  ```

  Pass = the verifier names the added line
  `git diff --name-only "$base" "$r" -- docs/handover` (its `cl_inflight`
  hunk) and says a deletion counts as a difference there. Paste what it
  returned. Fail = the prompt is wrong; fix the prompt, not the acceptance.
- `./joharness.sh review` on a branch carrying a workstream file — prints
  the depth it prints today, plus the verifier step. Paste both.
- `./joharness.sh review` on a branch with no workstream file — unchanged
  from today, still says it checked nothing.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests added.
  Trust the counted number, not this line.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — all checks pass, 0 failed. Required: the diff touches
  `joharness.sh`, a non-`*.md` file in step 7's list, and CI cannot run this
  one.
- `.agents/scripts/sync-to-consumer.sh --dry-run` against a scratch consumer
  reports `.claude/agents/verifier.md` among the files it would place.

## Where to look

- `joharness.sh:cmd_review` — where depth and the review record are already
  resolved and printed for this branch. The verifier line belongs here, not
  in a new subcommand.
- `joharness.sh:cl_inflight` — the escape itself, as it stands after PR59's
  fix. Read the comment there before writing the verifier's prompt: it
  names exactly what a reader had to notice.
- `.agents/docs/feedback.md`, Scoring — recurrence is the score, volume is
  not. The rule that picked one reader over three.
- `.agents/docs/agent-selection.md`, review depth — the recipe this plan
  amends, including the opus adversarial-lens wording that must now say
  which part a subagent runs.
- `.agents/docs/graph.md`, Rules — the diamond rule, stated and until now
  unenforced.
- `.agents/scripts/sync-to-consumer.sh` — the harness path list, and the
  `.claude/commands` / `.claude/skills` entries the new one sits beside.
- `.agents/docs/subagents.md` — the research this plan comes from: what a
  subagent can and cannot do here, measured, including the hook facts that
  rule out any way of handing it context except the spawn prompt.

## Traps

- The verifier's independence IS the deliverable. A prompt that pastes the
  session's reasoning, its plan, or its own findings recreates the context
  that missed PR54's bug and returns a second opinion that is the first one.
  Diff and rules; nothing else.
- No hook can hand a subagent state. `SessionStart` does not fire for
  subagents and `SubagentStart` cannot return `additionalContext` (measured
  2026-08-25). The spawn prompt is the only channel — so the diff goes IN
  the prompt, and a plan that relies on the subagent reading session context
  is broken before it runs.
- A diff is untrusted input. Any repo taking contributions can carry a hunk
  addressed to the reader, and this reader's output gates a merge — an
  injected verifier manufactures assurance, which is worse than no verifier.
  The prompt says data-never-instruction and the tool set is read-only, so
  the worst case is a bad finding rather than a bad commit.
- Conservative-reporting instructions lower recall in review tasks
  (`.agents/docs/agent-selection.md`, behaviour finding 5). The verifier's
  prompt says report everything and let the session filter. Never "only if
  certain".
- This plan edits `.agents/harness/AGENTS.md`. Under `JOHARNESS_MODE`
  unsupervised that commit is forbidden — a supervised session runs this
  plan.
- `.agents/harness/` must never name a specific environment. The verifier
  reviews any repo's diff; keep environment names out of both the rule and
  the agent definition.
- `.agents/harness/AGENTS.md` is the second hottest file in the repo (7
  edges) and `.agents/harness/selftest.sh` the hottest (9).
  `./joharness.sh feedback <path>` on each before touching them — what they
  already cost other branches is on the record.

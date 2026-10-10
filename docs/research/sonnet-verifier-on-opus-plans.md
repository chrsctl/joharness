---
research: sonnet-verifier-on-opus-plans
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/agent-selection.md
---

<!--
Split out of `docs/research/cost-per-merge-levers.md` when that node
closed: levers 1, 2 and 4 answered NO by ceiling and graduated
(`.agents/docs/agent-selection.md`, Cost levers). Lever 3 is the one whose
ceiling cleared the bar in one fleet. Recover the parent's readings:
`git log --diff-filter=D -- docs/research/cost-per-merge-levers.md`.
-->

## Question

In this repo's fleet, does a sonnet 5.5 verifier on opus-tier plans cut
cost per merged edge by at least 20% without more reverted merges or more
defects reaching `main`?

## Echo

In the parent's sample, verifiers in this repo's 10 opus-tier manager
sessions cost 21.93 USD, 37.1% of all 12 sampled managers (59.04 USD);
every subagent there was a `verifier`. Sonnet 5.5 bills half of opus 5.5
per token. At equal tokens the cut is 18.6% — under the bar. It clears
20% only if the sonnet verifier also spends at most ~92% of the opus
verifier's tokens. And the review-depth rule
says the verifier exists for independence, so a cheaper verifier that
misses defects costs reverts, which count against it. The gx fleet already
answered NO (16.0% even at a 100% cut).

## Sweep

`goal-directed` — enough paired verifier runs to fix the sonnet/opus token
ratio and compare findings on the same diffs; then a fleet trial only if
the ratio clears the bar.

## What would settle it

1. Token ratio: the same verifier prompt on the same 10 merged opus-tier
   diffs at sonnet 5.5 and at opus 5.5, cost read from each run. Median
   sonnet/opus cost ratio > 0.46 = NO (cannot reach 20%), no step 2. The
   0.46 uses the manager-only denominator, so it can only prove NO: at or
   below it the lever MAY reach 20%, and only the fleet trial in step 3,
   with orchestrator cost in, says whether it does.
2. Findings: for each of the 10 diffs, the merged edge's own `## Review`
   (the workstream file in git history) is the record. A finding the
   sonnet run missed that the record marks `(fixed)` = NO. Misses the
   record marks `wontfix` or `no change` do not count; neither does a
   finding of the fresh opus run that the record lacks.
3. No `(fixed)` miss = a fleet trial a human authorises (tier change =
   money): 10 merged edges each way, the parent's settling rule.

## Method

Sample: the 10 newest merged opus-tier edges in this repo whose workstream
file carries a `(verifier)` finding — PRs 402 400 399 395 394 393 389 387
386 384. Found by walking first-parent merges on `origin/main` and reading
`agent:` and `## Review` from each branch's deleted workstream file
(`git log --diff-filter=D <merge>^1..<merge>^2 -- 'docs/handover/*.md'`).

Head reviewed: the parent of the first branch commit that adds a
`- rN: (verifier` line to the workstream file. Findings commit with their
fix, so that parent is the tree round 1 saw. Round-1 record = the rN lines
that commit adds; later rounds saw later heads and are left out. Heads and
merge bases:

| PR | head | base | round-1 rN | of them `(fixed)` |
|----|------|------|-----------|-------------------|
| 402 | aae50ee783 | 298b9ac503 | r1-r14 | 13 |
| 400 | 1e1797a334 | 298b9ac503 | r1-r9 | 9 |
| 399 | dfaa0bbd36 | 298b9ac503 | r1-r8 | 7 |
| 395 | c79fe1bd3e | a6a50bd42f | r1-r11 | 10 |
| 394 | 30236dfdc2 | 906ff66ffc | r2-r7 | 6 |
| 393 | 2df56f1c88 | 50071e229d | r2-r9 | 3 |
| 389 | fee72ab43f | 64c12815b5 | r1-r9 | 8 (r2 in part) |
| 387 | 916b6a23c0 | 906ff66ffc | r1-r11 | 10 |
| 386 | 6326dee416 | 0d4ef4ea97 | r1-r11 | 10 |
| 384 | fb762c5c25 | fd0ac7d35f | r1-r8 | 8 |

Runs: 20 `verifier` subagents (`Agent`, `subagent_type: verifier`,
`model: sonnet` / `model: opus`; served as claude-sonnet-5-5 and
claude-opus-5-5 per transcript), all launched from one manager session in
one turn, each in its own detached `git worktree` at the head. Prompt
identical but for path and base: review `git diff <base> HEAD` per the
agent instructions, item named by the workstream file, report findings
most severe first with the breaking input, fix nothing.

Cost: each subagent's transcript
(`~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl`),
assistant messages deduped by message id, per-message `usage` priced at
the parent's rates (opus 5.5 4/20/0.20/5/8, sonnet 5.5 2/10/0.10/2.5/4
per MTok: input, output, cache read, 5m write, 1h write). Every write was
5m. Cost read after every run had stopped.

Findings match: a recorded `(fixed)` finding counts as found when the run
names the same defect at the same site (wording free); a partial hit counts
as found.

Second context: a verifier subagent that saw none of the matching
re-took it from the 20 transcripts and the round-1 records (see
Verification).

Confounds, named: 20 runs shared one container, so several `ci`
runs timed out and runs abandoned them; worktree `ci` inherits
`CLAUDE_PROJECT_DIR` pointing at the main checkout (one run saw
`ci: FAIL (1)` from the wrong tree, then re-ran with it set); worktrees
see today's `origin/main`, and one opus run (399) said it saw the fix
commit there. Each confound can only make a run find MORE, never fewer,
and only sonnet misses decide the answer.

## Findings

1. **Cost ratio: 0.209 median — step 1 does not say NO.** Sonnet / opus
   USD per diff: 402 0.1316/0.5515, 400 0.1579/0.4576, 399 0.1956/0.2933,
   395 0.4568/2.5354, 394 0.1447/1.4794, 393 0.1657/0.6062, 389
   0.0874/0.7873, 387 0.1017/1.3374, 386 0.0761/0.2851, 384 0.1362/1.1880.
   Ratios 0.076 to 0.667; summed 1.654 vs 9.521 USD (0.174). Under the
   0.46 bar, so the lever MAY reach 20% on cost. GROUNDED (re-taken, see
   Verification). Mechanism: sonnet stopped early — 5 to 27 tool calls
   against 9 to 63 for opus on the same diff; 7 of 10 sonnet runs handed
   back with `ci` still running and no result.
2. **Findings: NO.** Sonnet missed a recorded `(fixed)` round-1 finding on
   10 of 10 diffs. On 9 of them the fresh opus run re-found at least one
   of those misses, so the miss is the tier, not the head:

   | PR | `(fixed)` sonnet missed, opus re-found |
   |----|----------------------------------------|
   | 402 | r2 Echo overwritten; r4 37.1% mislabelled; r5 settle rule undefined |
   | 400 | r5 settle criterion replaced unsaid |
   | 399 | r4 pinning finding dropped; r6 stale "no order" |
   | 395 | r2 clean-pass line reds ci; r5 quiet ci hides churn; r6 finish hides promote |
   | 394 | r2 retire window offers a second planner |
   | 393 | r2 wrapper/path regression; r3 8 s nested-loop cost; r4 -eopid and `\|\|` exemption |
   | 389 | r3 done row never holds for a requirement; r8 stale reason; r9 which commit |
   | 386 | r1 ARCHIVED+new matches no row; r2 item-gone row below UNCLAIMED; r6 field row |
   | 384 | r1 lint reds `plan: <req>`; r2 dispatch sed misses product; r3 exits 2/4; r4 Satisfied bullet |
   | 387 | none (opus missed r1-r9 too) |

   Round-1 `(fixed)` findings found, of 84: sonnet about 17, opus about
   38; both well under the original rounds, so a fresh pass at either tier
   is not the record's equal — sonnet is half of opus. GROUNDED for the
   misses above (re-taken), WEAK for the two totals (match is judgement).
3. **The parent's ceiling priced the wrong opus.** Its 18.6% assumed opus
   5.5 rates, but the sample's verifiers ran under opus 5, where sonnet
   5.5 cuts up to 80% (cache read) — raised by a sonnet run on PR 402.
   Moot: step 2 is NO at any price.

Answer: NO. Sonnet 5.5 verifies opus-tier diffs at about a fifth of the
cost and misses defects the opus verifier catches on nearly every edge;
each miss is a defect that reaches `main` or a later round. No fleet trial
(step 3 needs no `(fixed)` miss).

## Consequence for the queue

None: NO, so no plan. The verifier keeps running at plan tier. (Was:
A YES becomes a plan a human authorises: the verifier tier rule in
`.claude/agents/verifier.md` and `./joharness.sh review`. Those govern
every consumer, and gx already answered NO, so the plan scopes the change
to fleets whose verifier share clears the bar — how is the human's call.)

## Verification

None yet.

## Graduates to

`.agents/docs/agent-selection.md` Cost levers.

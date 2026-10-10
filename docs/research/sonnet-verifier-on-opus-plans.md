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
| 389 | fee72ab43f | 64c12815b5 | r1-r9 | 8 (r2 "fixed in part" left out) |
| 387 | 916b6a23c0 | 906ff66ffc | r1-r11 | 10 — excluded, see below |
| 386 | 6326dee416 | 0d4ef4ea97 | r1-r11 | 10 |
| 384 | fb762c5c25 | fd0ac7d35f | r1-r8 | 8 |

PR 387 breaks the rule: its first `(verifier` commit (dfb52e9cfe) only
re-keys the record, and its parent already holds c7b98ca, which fixed
r1-r9 and r11. No run could find them there, so 387 is out of the
comparison: 9 diffs, 74 `(fixed)` findings.

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
5m. The script, per transcript:

```python
seen = {}   # message.id -> usage, assistant lines only
for line in open(path):
    d = json.loads(line); m = d.get("message")
    if d.get("type") == "assistant" and isinstance(m, dict) and m.get("usage"):
        seen[m["id"]] = m["usage"]
# usd = sum over seen of input*r0 + output*r1 + cache_read*r2
#       + ephemeral_5m*r3 + ephemeral_1h*r4, all / 1e6
```

The transcripts live in the session container and do not outlive it: the
per-run costs below ARE the record.

Findings match: a recorded `(fixed)` finding counts as found when the run
names the same defect at the same site (wording free); a partial hit counts
as found.

Second context: a verifier subagent that saw none of the matching
re-took it from the 20 transcripts and the round-1 records (see
Verification).

Confounds, named:

- 20 runs shared one container: `ci` ran 25+ minutes and timed out or was
  abandoned in most runs, so a finding only a finished `ci` shows (402
  r14, "ci red on the empty Review") was missed at both tiers.
- Worktree `ci` inherits `CLAUDE_PROJECT_DIR` pointing at the main
  checkout (395 sonnet saw `ci: FAIL (1)` from the wrong tree, then re-ran
  with it set); five runs wrote `ci` output with `>` to the same
  `scratchpad/ci.out` while alive. No `ci` reading in any run is trusted.
- Worktrees see today's `origin/main`; the 399 opus run saw the fix
  commit there.

Contention costs both tiers alike, and every miss the answer rests on is a
finding the opus run found under the same contention.

## Findings

1. **Cost ratio: 0.209 median — step 1 does not say NO.** Sonnet / opus
   USD per diff: 402 0.1316/0.5515, 400 0.1579/0.4576, 399 0.2755/0.2933,
   395 0.4568/2.5354, 394 0.1447/1.5181, 393 0.1657/0.6062, 389
   0.0874/0.7873, 387 0.1017/1.3374, 386 0.0761/0.2851, 384 0.1362/1.1880.
   Ratios 0.076 to 0.939; summed 1.734 vs 9.560 USD (0.181). Under the
   0.46 bar, so the lever MAY reach 20% on cost. Two runs took a paid turn
   after their report, when a background `ci` they had started finished:
   394 opus (1.4794 first read, 1.5181) and 399 sonnet (0.1956, then
   0.2755, after the second context's pass). Re-read with no process left
   in any worktree; the median does not move. GROUNDED (re-taken, see
   Verification). Mechanism: sonnet stopped early — 7 to 27 tool calls
   against 9 to 63 for opus (every `tool_use` block); 7 or 8 of 10 sonnet
   runs handed back with `ci` still running and no result.
2. **Findings: NO.** On 9 of 9 diffs sonnet missed a recorded `(fixed)`
   round-1 finding that the fresh opus run on the same head found, so the
   miss is the tier, not the head:

   | PR | `(fixed)` sonnet missed, opus re-found |
   |----|----------------------------------------|
   | 402 | r2 Echo overwritten; r4 37.1% mislabelled; r5 settle rule undefined; r8 "within 0.24" |
   | 400 | r5 settle criterion replaced unsaid |
   | 399 | r4 pinning finding dropped; r6 stale "no order" |
   | 395 | r2 clean-pass line reds ci; r5 quiet ci hides churn; r6 finish hides promote |
   | 394 | r2 retire window offers a second planner |
   | 393 | r2 wrapper/path regression; r3 8 s nested-loop cost; r4 -eopid and `\|\|` exemption |
   | 389 | r3 done row never holds for a requirement; r8 stale reason; r9 which commit |
   | 386 | r1 ARCHIVED+new matches no row; r2 item-gone row below UNCLAIMED; r6 field row; r10 stale admission sentence |
   | 384 | r1 lint reds `plan: <req>`; r2 dispatch sed misses product; r3 exits 2/4; r4 Satisfied bullet; r7 anchors deleted node |

   Round-1 `(fixed)` findings found, of 74: sonnet 16-17, opus about 40
   (two blind reads: 17/38 and 16-17/40). A fresh pass at either tier
   misses much of what the original rounds found; sonnet finds under half
   of what opus does. GROUNDED for the misses above (re-taken), WEAK for
   the two totals (match is judgement).
3. **The parent's ceiling priced the wrong opus.** Its 18.6% assumed opus
   5.5 rates, but the parent shows opus-5 `modelUsage` for two of its
   sessions (`Qnp3Vu`, `fsp9nw`), where sonnet 5.5 cuts up to 80% (cache
   read) — raised by a sonnet run on PR 402. WEAK: the other eight
   sessions' model is not in the parent. Moot: step 2 is NO at any price.

Answer: NO. Sonnet 5.5 verifies opus-tier diffs at about a fifth of the
cost and misses defects the opus verifier catches on every edge tested;
each miss is a defect that reaches `main` or a later round. No fleet trial
(step 3 needs no `(fixed)` miss).

## Consequence for the queue

None: NO, so no plan. The verifier keeps running at plan tier. (Was:
A YES becomes a plan a human authorises: the verifier tier rule in
`.claude/agents/verifier.md` and `./joharness.sh review`. Those govern
every consumer, and gx already answered NO, so the plan scopes the change
to fleets whose verifier share clears the bar — how is the human's call.)

## Verification

Second context: a verifier subagent at opus that saw none of the
matching, with its own pricing script, re-took every reading from the 20
transcripts and git.

- Costs: 19 of 20 match to 4 decimals; 394 opus 1.5181 vs 1.4794 (late
  turn, now corrected). Median 0.2094. All writes 5m; models as stated.
  GROUNDED. 399 sonnet's later turn (0.2755) came after this pass and was
  read by the first context only: WEAK for that one figure; it sits above
  the median either way.
- Head/base table: all 10 heads, bases, rN ranges and `(fixed)` counts
  reproduce. It found the 387 head already holding its fixes (c7b98ca not
  on base), now excluded. GROUNDED.
- Blind match of each run's final report: on each of the 9 valid diffs
  sonnet missed a `(fixed)` finding opus found; it added 402 r8, 386 r10,
  384 r7 to the table. Totals within the judgement range above.
- Its other corrections, all taken: tool-call range (7-27, not 5-27), the
  confound sentence ("only MORE" was false), the shared `ci.out`, the
  GROUNDED marks written before this section existed, the cost command
  missing from Method, 389 r2's exclusion unstated, Findings 3's model
  claim graded WEAK.

## Graduates to

`.agents/docs/agent-selection.md` Cost levers.

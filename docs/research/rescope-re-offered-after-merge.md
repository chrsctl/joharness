---
research: rescope-re-offered-after-merge
urgency: normal
agent: opus
effort: high
graduates: joharness.sh
---

<!--
Issue #300. Reported from a consumer by the route
`.claude/commands/upstream-report.md` names; canonical decides. The fleet
readings are about a live orchestrated run and could not be taken here. The
mechanism was read from this repo's source at `cb0028e`, and the reading
below finds a SECOND cause the issue does not name.
-->

## Question

What should suppress a second surveyor for a held plan whose first surveyor
already merged a conclusion that the remaining holds are genuine?

## Echo

An `OVERLAP-BOUND` verdict means slots are idle only because held plans'
declarations are too wide, and the one repair the rules allow is a single
surveyor. The bound against spawning a second is the orchestrator's ledger
entry, keyed on the collision — and the collision is named by the SET of
branches doing the holding. When a holder merges, the set shrinks, the key is a
different string, and the ledger entry no longer matches the thing being
offered.

What I am asking is which fact a suppression should rest on. The issue proposes
the held plan, and that is the natural answer. But a suppression needs a source
that survives the merge it is supposed to outlive, and reading the code I found
the drift is not the only reason the first surveyor's conclusion stopped
counting — so "key it on the plan" is a direction, not yet a mechanism.

## Sweep

`goal-directed` — enough to establish what the suppression reads today, why it
stopped holding in the reported instance, and which of the issue's three
options can survive the merge. Not a survey of the overlap machinery, and not a
re-derivation of the surveyor role.

## What would settle it

- **A source of truth that outlives the surveyor's own merge.** The suppression
  must still be readable when the surveyor branch is gone. Candidates: the
  held plan's `scope:` line (did a surveyor narrow it), the merged surveyor's
  retired workstream file in history, or a marker on the plan. Settled by one
  that a counted read can reach — never a written status field, which is the
  stored-copy failure `.agents/docs/graph.md` forbids.
- **Whether a genuinely NEW holder set must still get its own surveyor.** This
  is the invariant the current key protects, and it is in the code with the
  round that bought it. Any fix keyed on the plan has to answer what happens
  when a fourth branch joins the collision with a bad declaration of its own.
  Settled by naming the case and saying what fires.
- **Whether the conclusion is a fact or a judgement.** "These holds are
  genuine" was written by one session reading five files. If that is a
  judgement, a later surveyor at a higher tier may legitimately disagree, and
  the fix is a report line rather than a suppression. Settled either way, and
  the issue's own closing note is the argument for keeping the door open.

Written before the reads below: a fix that suppresses every second surveyor for
a plan has not answered this question if it also suppresses the first surveyor
for a new collision on that plan.

## Method

Source reads at `cb0028e`, each re-run rather than taken from the issue:

    sed -n '8594,8662p' joharness.sh          # the key, the settled flag
    grep -n "rescope_settled" joharness.sh    # one feeder, three lines
    sed -n '8712,8732p' joharness.sh          # the three OVERLAP-BOUND verdicts
    sed -n '7937,7988p' joharness.sh          # dispatch_rescope_branches
    grep -n "rescoped=" joharness.sh .claude/commands/orchestrate.md
    git log --oneline -3 -S"spawn ONE surveyor" -- joharness.sh

## Findings

- **The key is the holder set, and the code says so in its own comment.**
  `cb0028e`, the rescope block:

      # The key is the HOLDER set — the plans in flight whose exclusive claims
      # do the holding — sorted, joined with `+`, so the same collision reads as
      # the same key on every pass and the ledger's `rescoped=<key>` bound holds.

  So the issue's diagnosis is right about what the key is: it is built from
  `holdmap`'s holders, sorted and joined with `+`, and two of three holders
  merging produces a different string.

- **A SECOND cause, not named by the issue, and it fires on its own.** The
  only thing that suppresses the spawn instruction is `rescope_settled`, and
  that flag can be set only from a row returned by `dispatch_rescope_branches`
  — whose walk, at `cb0028e`, skips any ref that is an ancestor of the base
  branch:

      git -C "$ROOT" merge-base --is-ancestor "$r" \
        "refs/remotes/origin/${base_branch}" </dev/null 2>/dev/null && continue

  The flag is then set only `case "$rstat" in done | blocked)` **and**
  `[ "$rk" = "$rescope_key" ]`, and `grep -n rescope_settled joharness.sh`
  returns exactly three lines at `cb0028e` — the declaration, that one
  assignment, and the read in the verdict. One feeder, and it drops merged
  refs. So once the surveyor's own pull request merges there is no row at all,
  `rescope_settled` stays 0, and the spawn instruction returns — **with the key
  unchanged**. The drift makes it certain; the merge alone is sufficient.

  How much that skip drops, counted here 2026-10-08 on this repo's own refs
  with the same test the walk uses:

      while read -r r; do
        git merge-base --is-ancestor "$r" refs/remotes/origin/main \
          && echo skipped || echo listed
      done < <(git for-each-ref --format='%(refname)' refs/remotes/origin |
               grep -v '/HEAD$\|/main$') | sort | uniq -c

  140 skipped, 15 listed. The skip is correct for its purpose — a merged
  branch is not in flight — and it is also why a merged surveyor's verdict
  cannot be read from this walk at all.

  Any fix that only stabilises the key leaves this half open, and the reported
  instance had both: the first surveyor's pull request had merged eight minutes
  earlier AND two holders had stopped holding.

- **The key-blind ACTIVE count is deliberate, and the reason is in the code
  with the round that bought it.** `cb0028e`:

      # ANY active rescope holds off a spawn, whatever its key. … Keying
      # `n_rescope_inflight` to the current key let a stale-key rescope go
      # uncounted, its row suppressed, and the orchestrator spawn a second
      # onto the new key (verifier r1). So the ACTIVE count ignores the
      # key; only SETTLED is key-specific — a done rescope on an OLD key must
      # not settle a genuinely new holder set, or the new overlap never gets
      # its own rescope.

  This is the second bullet of `## What would settle it`, already answered
  once, in the opposite direction, for the in-flight case. A fix keyed on the
  plan is asking to reverse it for the settled case, so it owes the case the
  comment names: a new collision that would then never get a surveyor.

- **The quoted instruction's wording predates this repo's own rename.** The
  issue quotes `spawn ONE rescope manager (agent: sonnet) on key …`. At
  `cb0028e` the string is `spawn ONE surveyor (agent: sonnet) on key %s`;
  `git log -S"spawn ONE surveyor"` dates that rename to `ca36be1`, 2026-09-11,
  about four weeks before the issue was filed. So either the reporting copy
  was older than that commit or the quote was paraphrased. The MECHANISM the
  quote describes is current and unchanged — which is what matters here — but
  a reader checking the string against this tree will not find it, and the
  glossary fixes `surveyor` as the spelling.

- **Reported, not re-measured here: the instance.** At 23:08Z on 2026-10-07,
  `OVERLAP-BOUND` for one held plan with a three-branch key. One surveyor was
  spawned, narrowed a bare whole-directory claim to an enumerated file list,
  and merged; its handover recorded the rest as a conclusion — *"The remaining
  collision … is genuine and stays serialized."* Eight minutes after that
  merge, `OVERLAP-BOUND` printed again for the same plan, key now a single
  branch, `held on: … (1 held)`, `rescope branch(es) in flight: none`, and the
  instruction to spawn one surveyor on the new key. The orchestrator declined,
  and recorded that it was declining against the letter of the rule.

- **Reported, not re-measured here: what a second one costs.** A surveyor runs
  beyond the manager cap — *"it is the human's money"* — and the first cost
  about 5 USD. The issue does not claim a second would find nothing, only that
  the first read the same files and said not.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

What whoever takes it must carry in: **the issue's option 1 is necessary and
not sufficient.** Keying the check on the held plan stabilises it against the
holder set drifting, and does nothing about the merged surveyor's row being
gone — so the suppression still needs a source outside
`dispatch_rescope_branches`, which is the issue's option 2 (read the
conclusion from history) arriving as a requirement rather than an alternative.

And the invariant in the block's own comment is not optional: a done surveyor
on an old key must not settle a genuinely new holder set. A fix that forgets it
turns an over-spawn into a plan that can never be repaired, which is the more
expensive direction — the first costs one session, the second costs every
future collision on that plan.

Note for a parallel wave: a research node has no `scope:`, so the overlap guard
cannot see that this node and `plan-on-an-unmerged-branch` would both land in
`dispatch`'s branch walks. Taking both at once collides.

## Verification

Pending: the independent read of this branch.

## Graduates to

`joharness.sh` — specifically the rescope block in `cmd_dispatch` and
`dispatch_rescope_branches`, which is where the key is built, where
`rescope_settled` is decided, and where the merged-ref skip lives. The answer
is a change to what a counted read looks at, not a rule a session obeys; the
`rescoped=<key>` ledger line in `.claude/commands/orchestrate.md` follows from
it and is not the place the fact lives. The WHY belongs in the block's comment
beside the two verifier rounds already recorded there — that comment is what
stopped the last reader from keying the active count, and it is the only thing
that will stop the next one from keying the settled flag wrongly.

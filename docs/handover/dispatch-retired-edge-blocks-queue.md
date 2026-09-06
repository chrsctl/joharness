---
workstream: dispatch-retired-edge-blocks-queue
status: in-progress
branch: claude/drain-7uzyzi
pr: none
plan: dispatch-retired-edge-blocks-queue
issue: none
session: https://claude.ai/code/session_01V7Y1v6ee4aFAmDrY7W8SZZ
agent: opus
updated: 2026-09-06
next: Retire this file and the plan as the last commit before the pull request
---

## Goal

The serialisation PR #227 removed for HELD plans, reached through the other
reader. A branch past its retire commit carries no workstream file, so the
queue hook rightly calls its plan FREE and partitions it into a wave — while
`dispatch` withholds that item from the spawn list. The peer sharing one of
its paths is then told to WAIT for a pass nobody sits, and the verdict reads
`spawn nothing this pass` with slots free.

## Decisions

- **The hook keeps owning the partition; `dispatch` hands it the one fact it
  cannot see.** `QUEUE_WITHHELD` carries `<item>@<branch>`, computed once by
  `dispatch_retired_edges` where they already are. The alternative — the hook
  deriving retired edges itself — is a second copy of that scan, which is the
  shape this repo keeps paying for, and PR #228's own findings were two more
  instances of it.
- **The scan moved above the hook calls in `cmd_dispatch`.** That ordering is
  the fix: the set has to exist before the hook runs. Nothing else in the scan
  depends on the hooks, which is why it can move.
- **Every other caller partitions exactly as before.** `QUEUE_WITHHELD` unset
  means the same waves, the same holds, the same list — asserted directly,
  because "no regression for everyone else" is the claim most likely to be
  wrong and least likely to be noticed. The NOTE under the waves header did
  change wording for everyone, which is why a pre-existing assertion had to be
  updated: it now counts the two reasons separately.
- Not folded into the held count. A held plan waits on a manager that is
  working; a withheld one is at the edge with its pull request open. The note
  names them separately because the reader's next action differs.

## Rejected

- **Dropping the WAIT in `dispatch` when its note names a withheld item.**
  The note carries only the FIRST collision, so a plan that also meets a live
  claim would be released wrongly — the hazard this branch's own plan names,
  and the one PR #228 had just fixed on the HOLD side. The partition is where
  the whole set is known, so that is where the exclusion belongs.

## Review

One `verifier` pass at opus, seven findings, one of them a design defect in the
fix as first written.

- r1: (verifier, correctness) THE finding. Removing the WAIT installed no HOLD,
  so a peer overlapping a retired-edge item was spawned straight into a
  collision with a branch one merge from landing. Verified against both heads:
  pre-fix `zpeer … wave 2 WAIT`, my first fix `zpeer … wave 1` — and one commit
  earlier, before the retire, the same pair reads `HOLD … spawn once that
  branch merges`. The state with the STRONGEST reason to hold produced the
  weakest signal the command has. `.agents/docs/orchestrated.md` Concurrency
  argues HOLD for a claimed plan in the same words, and a retired edge is a
  claim in every sense except the file that was deleted on purpose. (fixed:
  the withheld items are passed as `<path>@<branch>` and the hook holds their
  peers off their paths, naming the branch; the item itself stays out of the
  partition. Pre-fix was starvation, my first fix was an unguarded reconcile,
  and neither was the answer.)
- r2: (verifier, correctness) a plan that was BOTH held and withheld was
  counted under each, so the note could claim more plans left out than the
  queue holds — `4 of them` out of `2 free plans`. The guard against
  double-counting WITHIN the held category was right there, three lines up.
  (fixed: withheld wins, counted once; a case withholds a plan that is also
  held and pins the total.)
- r3: (verifier, dead output) the withheld half of the note reaches no human
  today: `dispatch` is its only caller and never prints `qout`. (no change
  needed — with r1 fixed the information does reach the reader, as the peer's
  own HOLD line and the retired-edge row, which `dispatch` does print. The
  note stays for a direct reader of the hook, which is what the fixture is.)
- r4: (verifier, rules) the plan's Acceptance names a `bothsides` case that
  exists nowhere, and the new block added no case for a plan meeting both a
  withheld item and a live claim — the plan's own hazard, unpinned. (fixed:
  `zboth` meets `alpha` live and the withheld `aretired`, and is HELD.)
- r5: (verifier, docs) the new environment seam was documented in neither
  file a reader of either side would open. (fixed: `QUEUE_WITHHELD` is in the
  hook's own Environment block, and Concurrency gains the rule beside the
  three partition rules it already states.)
- r6: (verifier, record) "session start prints what it always did" was false
  as written — the partition is byte-identical, the note wording is not.
  (fixed: Decisions says which half changed.)
- r7: (verifier, nits) a doubled `i=0`, two blank lines where the scan block
  was lifted out, and one real consequence of the move: with
  `DISPATCH_FETCH=0 DRAIN_FETCH=1` the scan now reads refs before the handover
  hook's fetch rather than after. (fixed: both nits. The fetch ordering is
  left as it is — `dispatch` fetches for itself at the top by default, and the
  combination that differs sets one fetch off and the other on.)

## Blockers

None. The plan SHIPS; its cheap consumer-side version is the fixture, and the
full one needs a fleet this session cannot reach.

## Where to look

- `joharness.sh:cmd_dispatch` — the scan, now above the hook calls, and
  `DISPATCH_WITHHELD`.
- `joharness.sh:drain_hook` — the pass-through.
- `.agents/harness/queue-context.sh` — `free_withheld`, the partition skip and
  the note.

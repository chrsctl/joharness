---
plan: graph-inherited-workstream-label
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest.sh
---

## Goal

`./joharness.sh graph` labels an in-flight branch with a workstream file the
branch never wrote. It reads the branch's TREE, so every branch cut from a
base that carries a leftover workstream file inherits that leftover and gets
named after it — the branch shows in the graph as somebody else's finished
work rather than its own.

Found on PR 54 and recorded there as `r13`, deliberately not fixed in that
diff: it was pre-existing, out of that branch's scope, and the fix changes
`graph` output and the selftest cases that assert on it. `main`'s own
`joharness.sh` printed the identical wrong graph on the refs of the day. This
plan is that finding, carried forward — PR 54's workstream file was deleted
by the finish ritual and history is the only other place it lives.

The same confusion, in the same file, has already been fixed once. `cl_inflight`
had it (PR 54 `r8`: it protected a workstream file whenever any unmerged
branch's tree carried one, so the first run reported every leftover as work in
flight on the strength of the branch running the command). `cmd_upgrade` reads
it correctly today — `joharness.sh:cmd_upgrade` diffs `--diff-filter=A` against
`git merge-base HEAD origin/<base>` and falls back to presence only when there
is no merge-base to compare against. `cmd_graph` is the third caller and the
one still reading trees.

Inheriting is not claiming. That sentence is the whole fix.

**This is latent, not visible, and that is the trap.** The symptom needs a
leftover on the base branch to appear at all, and the base is clean as of this
plan being written. It re-fires the moment step 7 is skipped once — which the
session-start hook exists to count, and which PR 54 measured happening at a
rate of one merge removing two leftovers and the next merge adding one. Do not
conclude from a clean `graph` today that the defect is gone; build the fixture.

## Scope

- `joharness.sh` — `cmd_graph`'s per-branch workstream lookup, changed to ask
  what the branch INTRODUCED rather than what its tree holds.
- `.agents/harness/selftest.sh` — the `step "joharness.sh graph"` section, with
  a regression case for the inherited-vs-written distinction.

## Out of scope

- **`cl_inflight` and `cmd_upgrade`.** Both already read the diff. Touching
  them re-opens two fixed findings (PR 54 `r8`, `r9`) for no gain.
- **Any other `cmd_graph` behaviour** — the churn columns, the claim column,
  the dedupe on workstream name, the edge model. This plan changes which file
  is picked for a branch, nothing else about the view.
- **Sweeping leftover workstream files.** That is `cleanup`'s job and it is
  already done; this plan fixes the reader, not the data.
- **The `head -1` choice itself.** A branch carrying two workstream files it
  genuinely wrote still gets labelled by one of them. That is a separate
  question and picking at it here widens the diff past the finding.

## Acceptance

- A fixture branch that writes NO workstream file, cut from a base that
  carries one: `graph` does not name it after the inherited file. This is the
  regression for `r13` and it must go red before the fix.
- A fixture branch that writes its OWN workstream file, cut from that same
  base: `graph` names it after its own file, not the inherited one. Both
  halves, or the fix is "print nothing" wearing a passing test.
- A branch with no merge-base against the base branch degrades honestly —
  match whatever `cmd_upgrade` already does in that arm, and say in a comment
  which behaviour was chosen and why.
- Existing `step "joharness.sh graph"` cases still pass, or each changed
  expectation is justified in the workstream file's `## Review` as a
  deliberate output change rather than edited to fit.
- `./joharness.sh ci` — `ci: pass`. Trust the counted number, not this line.

## Where to look

- `joharness.sh:cmd_graph` — the `ls-tree -r --name-only "$r" -- docs/handover`
  lookup piped through `gr_docs | head -1`. This is the defect.
- `joharness.sh:cmd_upgrade` — the merge-base block that already does it
  right, including the no-merge-base fallback and the comment explaining why
  it refuses on presence there.
- `joharness.sh:gr_docs` — the shared filter that drops `TEMPLATE.md` and
  `README.md`; reuse it, do not re-spell it.
- `.agents/harness/selftest.sh:step "joharness.sh graph"` — where the cases go.

## Traps

- `cmd_graph` walks REMOTE refs, not the working tree, so the merge-base is
  between the remote ref and the base branch — not `HEAD` and the base, which
  is what `cmd_upgrade` needs and what a copy-paste of it would give you.
- Trust counted numbers, never written numbers, including every number on this
  page.
- A fixture that only plants the inherited case passes just as well against a
  fix that prints nothing at all. Both halves, always.

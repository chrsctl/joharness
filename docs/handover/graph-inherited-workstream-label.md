---
workstream: graph-inherited-workstream-label
status: review
branch: claude/graph-inherited-workstream-label
pr: none
plan: graph-inherited-workstream-label
session: https://claude.ai/code/session_013gbMpgGTeYzxsBa7RfW4ch
agent: opus
updated: 2026-08-25
next: Merge PR 76 first (this branch is stacked on it), then delete this file and the plan file, open the pull request and merge per Loop step 7
---

## Goal

`docs/plans/graph-inherited-workstream-label.md` — PR54 r13, the sixth
caller of the tree-vs-diff class. `cmd_graph` read each branch's TREE to
decide which workstream file names it, so every branch cut from a base
carrying a leftover was drawn as a node named after somebody else's finished
work. Tier escalated sonnet → opus (allowed), because the plan's own Traps
warn that the obvious copy-paste of the existing fix is the wrong one here.

## Decisions

- **Merge-base is between the REMOTE ref and the base ref, not `HEAD` and the
  base.** This loop walks refs, not the checkout. `cmd_upgrade` and
  `fin_adds_at` both compare against `HEAD` because they describe the current
  session's branch; copying either form here would have compared every remote
  branch against this checkout and produced nonsense. The plan flagged this
  in Traps and it was the one real trap in the change.
- **The no-merge-base arm falls back to presence and keeps drawing the
  branch.** `graph` DESCRIBES, and the repo already states the doctrine
  beside `base_ref`: it "would rather lint the checkout it has than refuse".
  `upgrade` makes the opposite call from the same ambiguity because it
  DECIDES. Both are right; the comment now says which is which and why, so
  the next reader does not "fix" one into the other.
- **A branch with no workstream file of its own is simply not a node.** It has
  no claim, so it has nothing to be a workstream node for. The pre-existing
  `[ -n "$ws" ] || continue` already did the right thing once `ws` became
  honest — no new branch of control flow.
- **Reused the fixture instead of building one.** `inheritor` (cut from a main
  carrying two rotted files, writes none of its own) and `rival` (writes its
  own) already existed for the handover hook's tests. The defect needed
  exactly that pair, which is some evidence the fixture was modelling the
  right thing all along and only `graph` was not reading it.

## Rejected

- **Fixing `head -1` at the same time.** A branch carrying two workstream
  files it genuinely wrote still gets labelled by one of them arbitrarily.
  Named out of scope in the plan; widening here would have buried the
  ownership change in a second argument.
- **Asserting on the exact leftover node name.** `head -1` picks between
  `stale-ws.md` and `stale-ws-two.md` by sort order, which is an
  implementation detail of the thing under test. One `refute` on the shared
  stem `b_stale_ws` covers both and does not encode the ordering.

## Review

- r1: first assertion guessed the node label as `b_rival_ws["branch: rival`
  and went red immediately. The real format is a stadium node,
  `b_rival_ws(["rival-ws"]):::branch`. Caught by running it, not by reading —
  which is the point of writing the assertion before trusting the shape.
  (fixed)
- r2: mutation-tested against the reverted tree read. The inherited case goes
  RED, the companion "a branch that wrote its own file is still a node" stays
  GREEN. Both directions matter: without the companion, the fix passes just
  as well against a `graph` that stopped drawing branch nodes entirely, which
  is exactly the vacuous-pass failure the plan's Acceptance demanded be ruled
  out and which PR69 r3 shipped twice in this repo. (fixed — proven)
- r3: `mb` added to the function's `local` list. Under `set -u` a missed
  local is a latent failure in a long function, and this one already declares
  eleven. (fixed)
- r4: checked that no other node id contains the substring `b_stale_ws`
  before relying on a `refute` against it — a refute that can never match is
  a test that can never fail. (no change needed — verified)
- r5: read `feedback joharness.sh` (8 edges) and
  `feedback .agents/harness/selftest.sh` (10 edges) first, per step 5. PR54
  r13 IS this work. PR72 r1 is the same class arriving from the finish gate
  and confirms the diff-not-tree shape used here. Nothing else re-fires.
  (no change needed)
- r6: this branch is stacked on `claude/verify-none-layer` because the two
  plans conflict on `joharness.sh` — the queue's own wave analysis puts them
  in different waves for that reason. Recorded so the merge order is not a
  surprise: PR 76 first, then this. (no change needed — deliberate)

## Blockers

None. Ordering only: PR 76 merges first.

## Where to look

- `joharness.sh:cmd_graph`, the `mb` block — the diff read, and the comment
  explaining why the describing/deciding split sends `graph` and `upgrade`
  opposite ways on the same ambiguity.
- `.agents/harness/selftest.sh`, `step "joharness.sh graph"` — the refute and
  its companion. The companion is the half that stops the fix passing
  vacuously.
- `docs/plans/tree-vs-diff-rule.md` — the rule this defect is the sixth
  instance of; that plan writes it down so there is no seventh.

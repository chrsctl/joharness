---
plan: orchestrator-inflight-count
urgency: urgent
agent: opus
effort: xhigh
needs: none
requirement: orchestrated-mode
scope: joharness.sh, .claude/commands/orchestrate.md, .agents/docs/orchestrated.md
---

## Goal

`dispatch` reports a live manager's slot as free for the whole window between
its pull request opening and merging, and re-offers the item it holds. An
orchestrator acting on that verdict spawns a duplicate per item and exceeds
`JOHARNESS_MAX_MANAGERS`, which is the human's money.

Found by the orchestrator of run 1 (`.agents/docs/orchestrated.md`, Runs),
which declined the verdict on 11 consecutive health passes and cross-checked
every one against the control plane. Consumer `chrsctl/gx`, 2026-09-06.

## The mechanism — and the part that is deliberately correct

`cmd_dispatch` builds each in-flight row from the workstream file's `plan:` on
a pushed branch — the queue hook's `claimed on <branch>`. Loop step 7 requires
that file retired **as the last commit before the pull request opens**
(`.agents/docs/handover/README.md`, Graduation; `finish` gates it).

**Read this before proposing anything.** That a retired file stops being a
claim is not an oversight — it is pinned, with reasoning, in
`.agents/harness/selftest/handover-context-owns.sh:85`:

```
refute "and a branch that RETIRED it is not in flight either" \
  "origin/retirer: docs/handover/swept.md" "$out"
```

The surrounding comments are careful about exactly what that refute covers
and why a wider one was wrong. **Keep it green.** A retired file genuinely is
not a claim; the claims view is right.

The defect is one layer up: **`slots` answers a different question with the
claims view's value.** A claim says *who owns this item*. A slot says *how
much of the human's money is committed right now*. Those diverge for exactly
the PR-open-to-merge window, where a manager holds a branch, a pull request,
CI and a container while holding no claim — and that is the window in which
duplicating it is most expensive.

One value serving two questions is the shape ADR-style reasoning in this
repo keeps re-finding. The fix belongs on the capacity side, not by loosening
what counts as a claim.

## The measurement

11 consecutive passes, 12:44Z–17:38Z, cap 4. Worst case, the 15:24Z pass:

```
slots     : 4 of 4 free
spawn, in this order, one manager per item, model = its agent tier:
  docs/plans/crm-aggregate-reasoning.md (agent: opus)  wave 1
  docs/plans/ui-storyboard.md (agent: opus)  wave 1
```

`get_session` on both at 15:24Z: RUNNING, connected, pull requests #295 and
#296 open. The git view reported the whole fleet idle while it sat at cap. Four
such items and the fleet doubles.

## Scope

- Make `slots` count a branch that is ahead of its base and unmerged as
  in flight when it carries no claim file, or print it as a distinct row
  (`PR in flight, no claim file`) excluded from the count. Either keeps the
  retire ritual untouched.
- The row must still be distinguishable from a genuinely abandoned branch, or
  this trades a duplicate-spawn defect for a slot that never frees. A merged
  branch already drops out; an unmerged one with no session is the case that
  must stay respawnable.
- Say in `.claude/commands/orchestrate.md` that the control-plane check is
  load-bearing for the COUNT, not only a per-row confirmation before spawning.
  Run 1 read it as the latter, correctly, and was saved only by choosing to
  distrust the printed number.
- Runs row in `.agents/docs/orchestrated.md` gains nothing here; it already
  carries the count.

## Out of scope

- **Moving the retire commit after the merge.** The obvious repair, and it
  reverses a rule with eight pull requests of evidence: three that deferred
  the deletion each turned the base branch red within seconds
  (`.agents/docs/handover/README.md`, Graduation). The ritual is right.
  Reject this in the pull request body, not silently.
- **Making a retired file count as a claim again.** That is the other obvious
  repair and it is worse: it would red
  `.agents/harness/selftest/handover-context-owns.sh:85`, a pin whose comments
  record an earlier attempt at a wider refute failing for a good reason. The
  claims view is not the thing to change. Never relax a guard to make room for
  a fix one layer above it (`.agents/docs/feedback.md`, stage 1).
- Changing `JOHARNESS_MAX_MANAGERS` or any other knob. The cap held.

## Acceptance

- A branch that is unmerged, ahead of base, and carries no workstream file is
  NOT counted in `slots` and its item is NOT printed as free. Asserted with a
  fixture in that exact state — file retired, branch unmerged — because that
  is the state 11 passes hit and no existing check reaches.
- The fixture can fail: build the same branch WITH its workstream file present
  and the row appears as an ordinary claim; delete the file and the new row
  appears. Green both ways pins nothing.
- A merged branch still drops out entirely, and an unmerged branch with no
  live session is still offered for respawn. Both asserted, or the fix
  strands slots.
- **`.agents/harness/selftest/handover-context-owns.sh` still passes
  unchanged**, the `RETIRED` refute included. If the fix needs that file
  edited, the fix is in the wrong layer — go back to the claim/capacity
  split above.
- **Consumer-side** (this plan SHIPS): in a consumer running orchestrated
  mode, open a pull request from a manager branch, retire its workstream file
  first as step 7 requires, and run `./joharness.sh dispatch` there. Its item
  must NOT appear under `spawn` and `slots` must not count that manager's
  slot as free. Canonical cannot check this — it has no fleet and no
  consumer — so a bar met only here is met in the one repo that was never the
  risk (`.agents/docs/plans/README.md`, SHIPS). The reproduction is
  `chrsctl/gx` on 2026-09-06; a fresh consumer needs only one manager and one
  open pull request.

## Where to look

- `joharness.sh:cmd_dispatch` — the `--- managers in flight` loop; the claim
  is the workstream file's `plan:` read with `git show` off the branch.
- `.claude/commands/orchestrate.md` — step 1 (dispatch is the whole read) and
  the Tools table, which already says push age and control-plane status are
  two signals that must both be read.
- `.agents/harness/AGENTS.md` Loop step 7 — read before touching the retire
  ordering.

## Traps

- A count that reads the tree rather than the diff gets the wrong answer on an
  inherited file (`.agents/docs/feedback.md`, tree or diff).
- The fix is in the reader, so its check must drive the READER — assert on
  `dispatch` output, not on a helper the real path may not call
  (ADR-shaped lesson: measure the machine, not the model of it).

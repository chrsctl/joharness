---
research: a-requirement-no-plan-can-serve
urgency: normal
agent: opus
effort: high
graduates: .agents/docs/product/README.md
---

<!--
A report from a consumer (`chrsctl/gx`), filed by the route
`.claude/commands/upstream-report.md` names. Canonical decides; this session
answers nothing and changes no harness file.

The consumer's own numbers — commits on one requirement, planning passes,
dollars — could not be taken here. `add_repo` for that repository was
REFUSED in this session (auto-mode permission classifier) and the GitHub
tools refuse an out-of-scope repository, so nothing on the consumer side was
read at all. Every such claim below is marked REPORTED and carries that
reason. Everything about this harness was measured here, at `832f5fdd`.
-->

## Question

What can ever stop `./joharness.sh dispatch` offering a requirement as
`UNPLANNED`, when the one test that silences the row is a plan on the base
branch carrying `requirement: <its stem>` and no such plan will be written?

## Echo

The row is computed on every pass, never stored. It asks one thing: does any
open plan name this requirement. A requirement whose remaining clauses are
all either declined by the requester or already owned by a plan filed under a
DIFFERENT requirement answers no, and goes on answering no — there is no
plan left to write that would name the stem, and the requirement file is
still in the tree because the rule that deletes it needs a plan's pull
request to do it.

So what I am asking is not "is the `UNPLANNED` test wrong". It is right about
what it measures. I am asking whether the harness has any way to represent a
requirement that is finished with planning but not satisfied, and if it has
none, which of the two things gives: the test that keeps offering it, or the
lifecycle rule that says a requirement nobody has served is work rather than
a retire candidate.

What rests on the answer is money in a fleet nobody is watching. The
orchestrator's rule for an `UNPLANNED` row is one planning manager at opus,
effort xhigh. A row that cannot be silenced is a standing order for that
manager, once per orchestrator run, for as long as the file stands.

## Sweep

`goal-directed` — enough to name every reader that could suppress the row,
whether anything can hold or claim a requirement while a planner works on
it, and which written rule an answer would have to amend. Not a survey of the
requirement lifecycle. Not a decision on whether declining a clause is
legitimate: that is the requester's, and it is assumed here, not argued.

## What would settle it

Fixed before the fixture in `## Method` ran, and before any of its five
cases returned a result. The three source reads that preceded it are the
first block of the method and are named there as orientation.

- **Every input the silencing test reads.** If the test reads one field of
  one file set on one ref, the suppression candidates are enumerable and the
  question closes on that list. Settled by naming the inputs, not by
  describing the output.
- **Whether a requirement can be CLAIMED at all.** A plan row can read
  `claimed on <branch>`, `HOLD` or `WAIT`. If the claim vocabulary admits
  only plan and research stems, then a requirement row can never have a
  holder, and a second planner is not prevented by anything — which makes
  the re-offer a property of the data model rather than of a threshold.
  Settled either by finding a claim path that reaches `docs/product/`, or by
  showing there is none.
- **Which written rule an answer collides with.** The requirement lifecycle
  already has exactly two exits
  ([`../product/README.md`](../../.agents/docs/product/README.md)). If both
  need a plan or a requester, a marker a session may write is not a gap being
  filled — it is an amendment to a rule that was written deliberately, and
  the question is which half gives. Settled by quoting the rule, not by
  proposing a field.
- **What would NOT settle it:** a number. The consumer's spend is the reason
  this was filed and it is unverifiable here. If the harness-side finding
  held only because five passes were expensive, the node would be an
  anecdote. It must stand on what the code can and cannot represent.

## Method

Three orientation reads first, at `832f5fdd`, which fixed the section above:

    sed -n '600,680p' .agents/harness/queue-context.sh
    sed -n '8520,8600p' joharness.sh
    sed -n '1,70p' .agents/docs/product/README.md

Then the enumeration:

    grep -n 'served="$(awk' .agents/harness/queue-context.sh
    grep -n 'grep -qxF -- "$(stem' .agents/harness/queue-context.sh
    grep -n 'for cand in "docs/plans/${plan}.md"' joharness.sh
    grep -n "claimed_on=" .agents/harness/queue-context.sh
    grep -n "Owns one: it IS a claim" joharness.sh
    grep -rn "declin" .agents/docs/ .agents/harness/ joharness.sh .claude/commands/
    grep -n "UNPLANNED\|requirement" .agents/harness/selftest/dispatch.sh
    awk '/^queue_files\(\)/,/^}/' .agents/harness/queue-context.sh

Then a fixture, because a grep cannot tell a structural invisibility from a
fixture artifact — and the first run of this one was exactly that artifact:
it omitted `git remote add origin`, every push failed, and the queue hook
fell back to `HEAD` (`queue-context.sh:70-86`). The in-flight walk reads
`origin/<branch>` refs, so "no row for the planning branch" meant nothing in
that run. Re-run with the remote; cases A–E below are from the re-run.

```bash
#!/usr/bin/env bash
set -u
ROOT=<this checkout>
TMP="$(mktemp -d)"
W="${TMP}/work"; O="${TMP}/origin.git"
git init -q --bare "$O"
git init -q "$W"
git -C "$W" symbolic-ref HEAD refs/heads/main
mkdir -p "$W/docs/plans" "$W/docs/handover" "$W/docs/research" "$W/docs/product" \
         "$W/.agents/harness" "$W/.agents/env/none"
cp "$ROOT/joharness.sh" "$W/joharness.sh"
cp "$ROOT/.agents/harness/queue-context.sh" "$ROOT/.agents/harness/handover-context.sh" \
   "$W/.agents/harness/"
printf '# none\n' >"$W/.agents/env/none/AGENTS.md"
printf 'JOHARNESS_ENV=none\nJOHARNESS_MODE=orchestrated\n' >"$W/joharness.conf"
printf 'code\n' >"$W/code.txt"
git -C "$W" remote add origin "$O"
ci() { git -C "$W" add -A; git -C "$W" -c user.email=f@x -c user.name=f commit -qm "$1"; }
push() { ci "$1"; git -C "$W" push -q origin main; }
disp() { ( cd "$W" && JOHARNESS_CONF="$W/joharness.conf" DISPATCH_FETCH=0 \
            JOHARNESS_CURATE_HOURS=0 ./joharness.sh dispatch 2>&1 ); }
push base

# A: a requirement, and a plan filed under a DIFFERENT requirement.
printf -- '---\nrequirement: alpha-req\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- A clause.\n' >"$W/docs/product/alpha-req.md"
printf -- '---\nrequirement: other-req\npriority: normal\n---\n\n## Goal\nFixture.\n\n## Satisfied when\n\n- A clause.\n' >"$W/docs/product/other-req.md"
printf -- '---\nplan: beta\nurgency: normal\nagent: sonnet\neffort: high\nneeds: none\nrequirement: other-req\n---\n\n## Goal\nFixture.\n' >"$W/docs/plans/beta.md"
push "a requirement nobody serves, plus a plan under another requirement"
disp

# B: a requirement-planning branch, PUSHED, with a workstream file whose
#    plan: is none — which is the only thing it can be, the plan not existing.
git -C "$W" checkout -q -b claude/alpha-req-plan-pass
printf -- '---\nworkstream: alpha-req-plan-pass\nstatus: in-progress\nbranch: claude/alpha-req-plan-pass\npr: none\nplan: none\nissue: none\nsession: https://claude.ai/code/session_x\nagent: opus\nupdated: 2026-10-08\nnext: Decompose alpha-req into plans\n---\n\n## Goal\nPlanning pass on the requirement.\n' >"$W/docs/handover/alpha-req-plan-pass.md"   # (full fixture file also carries the template's other sections)
ci "claim the planning pass"
git -C "$W" push -qu origin claude/alpha-req-plan-pass
git -C "$W" checkout -q main
disp; disp | grep -c "alpha-req-plan-pass"

# C: a plan on main naming the stem.
printf -- '---\nplan: alpha-one\nurgency: normal\nagent: sonnet\neffort: high\nneeds: none\nrequirement: alpha-req\n---\n\n## Goal\nFixture.\n' >"$W/docs/plans/alpha-one.md"
push "one plan naming the stem"
disp | grep -c "docs/product/alpha-req.md — UNPLANNED"

# D: that plan retires; the requirement file is left standing.
rm "$W/docs/plans/alpha-one.md"
push "the plan retires; the requirement file stays"
disp | grep -c "docs/product/alpha-req.md — UNPLANNED"

# E: CONTROL. Same branch, same workstream file, ONE field changed.
printf -- '---\nplan: gamma\nurgency: normal\nagent: sonnet\neffort: high\nneeds: none\nrequirement: none\n---\n\n## Goal\nFixture.\n' >"$W/docs/plans/gamma.md"
push "a plan the control can claim"
git -C "$W" checkout -q claude/alpha-req-plan-pass
git -C "$W" merge -q --no-edit main
sed -i 's/^plan: none$/plan: gamma/' "$W/docs/handover/alpha-req-plan-pass.md"
ci "control: same branch, same file, plan: gamma"
git -C "$W" push -q origin claude/alpha-req-plan-pass
git -C "$W" checkout -q main
disp; disp | grep -c "alpha-req-plan-pass"
```

And the same fixture state read by the supervised entrypoint, to see whether
the re-offer is a property of the mode or of the queue:

    printf 'JOHARNESS_ENV=none\n' > conf-sup
    JOHARNESS_CONF="$PWD/conf-sup" DRAIN_FETCH=0 JOHARNESS_CURATE_HOURS=0 \
      ./joharness.sh drain

One caveat on the transcript, stated rather than cleaned up: the first push
to a fresh bare repository prints `fatal: expected 'acknowledgments',
received 'packfile'` followed by `warning: push negotiation failed;
proceeding anyway with push`. The push lands — `git -C "$O" for-each-ref`
lists `refs/heads/main` and `refs/heads/claude/alpha-req-plan-pass` — and
case E depends on those refs being readable, so the transcript's one `fatal`
is noise from the local git version, not a failed setup.

## Findings

- **One test silences the row, and it reads one field of the plan files on
  one ref.** `served` is the `requirement:` value of every open plan row
  (`queue-context.sh:644`), and a requirement is listed unless its stem is in
  that set (`:650`). The plan set comes from `git ls-tree -r "$ref" --
  docs/plans` (`queue_files`, `:63-67`), `ref` being `origin/<base>` where it
  exists (`:70-86`). So a plan filed under another requirement contributes
  only its own stem, and a plan on an unmerged branch contributes nothing.
  Measured, case A: with `docs/plans/beta.md` carrying
  `requirement: other-req`, dispatch prints

      docs/product/alpha-req.md — UNPLANNED: one planning manager (agent: opus, effort xhigh) first

- **A requirement cannot be claimed. There is no code path by which it
  could.** Every claim resolution in the harness offers exactly two candidate
  directories — `joharness.sh:5362`, `:5371`, `:7271`, and the same pair
  inside `dispatch_retired_edges` — and the queue hook keys a claim on a plan
  or research stem (`queue-context.sh:487`, `:882`). `docs/product/` appears
  in none of them. The workstream file has no field that could name a
  requirement either: `plan:` is the claim
  ([`../handover/TEMPLATE.md`](../handover/TEMPLATE.md)), and a planner has no
  plan to name. So the `UNPLANNED` row is printed with no holder and no
  hold annotation at all (`joharness.sh:8562-8572`), where every plan row can
  read `claimed on`, `HOLD` or `WAIT`.

- **A requirement-planning branch that HAS pushed appears nowhere in
  dispatch, and costs no slot.** Measured, case B: with
  `origin/claude/alpha-req-plan-pass` carrying a workstream file, status
  `in-progress`, dispatch mentions the branch and its file **0 times**, still
  prints the `UNPLANNED` row, still prints `slots : 4 of 4 free`, and still
  verdicts `NOT DRAINED — 2 free item(s) now, 4 slot(s): spawn up to 2 now`.
  The CONTROL is case E: same branch, same workstream file, one field changed
  from `plan: none` to `plan: gamma`, and the row appears —

      docs/plans/gamma.md  claude/alpha-req-plan-pass  in-progress  pushed 0m
      slots     : 3 of 4 free

  — so the invisibility in B is the claim field having nothing to say, not
  the fixture. The source says the same thing from the other end:
  `dispatch_retired_edges` skips any branch that ADDS a workstream file,
  because *"Owns one: it IS a claim and the claims view already listed it"*
  (`joharness.sh:7236`). For a `plan: none` file both halves of that are
  false — it is not a claim, and the claims view did not list it — so the
  branch falls out of both walks and is counted by neither.

- **The `UNPLANNED` spawn rule is the only one in the orchestrator's step 3
  with neither an in-flight condition nor a ledger key.** `orchestrate.md`:
  the requirement rule is two lines (`:453-454`); the curator may spawn
  *"ONLY when no curate branch is in flight … and your ledger has no
  `curated=` for this run"* (`:455-465`); the janitor the same with `swept=`
  (`:466-480`); the surveyor the same with the `rescope :` block (`:480-`).
  The general bound at `:441` — *"An item your ledger already names is
  spawned ONLY when THIS pass's health pass said to"* — is the ledger, and
  the ledger is per-run: *"First start = an empty ledger"* (`:77`).
  `JOHARNESS_PENDING_SPAWNS` likewise counts only the `@new` entries of the
  ledger the running orchestrator carries (`:84-88`). So nothing suppresses
  the row across orchestrator runs, and the thing that could suppress it
  within a run is a memory the next run does not inherit.

- **The row comes BACK when the last plan serving a requirement retires, if
  the requirement file is left standing.** Measured, cases C and D: a plan
  carrying `requirement: alpha-req` silences the row (0 matches); deleting
  that plan — which is what step 7 does at retirement — restores it (1
  match). This is the lifecycle working as written, and it is listed here
  because it is the second way into the same state: the loop does not need a
  declined clause to start, only a requirement that outlives its plans.

- **Both exits from the requirement lifecycle need something that may never
  arrive.** *"**Satisfied** = last plan's PR deletes the requirement file
  with the plan file"* — which needs a plan to exist. *"**Retired
  unsatisfied** = the REQUESTER decides … Never a session's call alone …
  and never inferred from a stale file — a requirement nobody has served is
  UNPLANNED, which is work, not a candidate for this"*
  ([`../product/README.md`](../../.agents/docs/product/README.md), `:26-36`).
  That last clause is the sentence any answer has to amend, and it is pointed
  the other way: it was written to stop a session retiring a requirement
  because the queue looked quiet. The case here is not a quiet queue — it is
  a requirement whose clauses have been answered, by a decline the requester
  made or by a plan filed elsewhere — and the rule as written cannot tell
  those apart from the stale file it was built to protect.

- **The harness has no word for a declined clause.**
  `grep -rn "declin" .agents/docs/ .agents/harness/ joharness.sh
  .claude/commands/` returns no rule about requirements: the hits are a
  consumer-bootstrap message, four selftest fixtures, a review `wontfix`
  example, and one record of a requester declining three proposals in
  `.agents/docs/unsupervised.md:291`. So a decline exists as something a
  requester did once, never as something a reader can see.

- **Not orchestrated-only. The spend is.** The same fixture state, read by
  the supervised entrypoint, names the same file as the next item:

      NOT DRAINED — a requirement has no plans, and planning outranks the plan queue
        next: docs/product/alpha-req.md [normal, UNPLANNED — decompose into plans]

  The test lives in the queue hook, so every mode sees it. What differs is
  who pays: a supervised session is a human reading a line; an orchestrator
  spawns opus at xhigh without being asked.

- **No selftest pins this shape.** `grep -n "UNPLANNED\|requirement"
  .agents/harness/selftest/dispatch.sh` returns the declutter cases and
  `requirement: none` frontmatter, and nothing that puts a requirement-
  planning branch in flight. So cases B and E above are green today and were
  never green on purpose.

- **REPORTED, not re-measured: the consumer's loop and its cost.** As filed:
  eight commits on one requirement file, five of them full re-measurement
  passes, each pass an opus manager at xhigh costing about $15–25, the fifth
  breaking the loop only because it happened to find one unasserted clause
  and wrote a plan naming the stem; and four consecutive orchestrator
  dispatch outputs listing that requirement `UNPLANNED` with no row for the
  planning branch that was running throughout. **None of this was read.**
  `add_repo` for the consumer repository was refused in this session by the
  auto-mode permission classifier, and the GitHub tools refuse a repository
  outside this session's scope, so the commits, the pull request body, the
  dispatch outputs and the dollar figures could not be opened. They are the
  reporting session's, at its strength, and **no finding above rests on
  them** — the harness-side half was measured here and would hold if every
  number in this paragraph were wrong. Canonical should treat the cost as
  the reason the question was asked, never as evidence for an answer.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

The candidates, as candidates. Each is a direction with a known collision,
and none is decided here:

1. **Give a requirement a claim.** Let a workstream file name a requirement
   (a new field, or `plan:` resolving a third directory), so a planning
   branch holds the row the way a plan branch holds a plan. Smallest change
   to the lifecycle; it fixes the duplicate-spawn and the slot count and
   fixes NOTHING about the requirement that no plan can ever serve — the row
   returns the moment the planner's branch merges.
2. **A marker that says planned out.** Frontmatter on the requirement, or a
   retire rule a planner may apply when every remaining clause is declined
   or owned elsewhere. This is the only candidate that ends the loop, and it
   is a direct amendment to `product/README.md:30-36`. The question canonical
   has to answer first is whether a requester's recorded decline is the
   requester deciding — if it is, the rule's "never a session's call alone"
   is satisfied by the decline and the session is only writing it down; if it
   is not, this candidate is out and (3) is out with it.
3. **Make the decline readable instead.** Leave the requirement rule alone
   and give the harness a word for a declined clause with its reversal
   trigger, then let the silencing test read clauses rather than plans.
   Largest change, and the only one that keeps the requirement file saying
   what is true.
4. **Leave the row and bound the spend.** Worth naming so it can be
   rejected explicitly: the cost here is not one expensive manager but many
   cheap-to-start ones, each terminating normally, so a per-manager ceiling
   (#317's `no-ceiling-on-one-item`) does not fire on any of them.

**Neighbours, checked. None of them carries this question:**

- `plan-on-an-unmerged-branch` (#317, issue #297) is LATENCY on the same
  test: a plan exists but is invisible until it merges. Its fix — read
  branches, or merge plan-only pull requests fast — does not reach a
  requirement for which no plan will be written.
- `plan-identity-is-its-filename` (#319) is the duplicate-plan collision,
  keyed on declared `scope:` paths. A requirement row has no `scope:` and no
  holder at all, so that machinery never applies to it.
- `a-manager-blocked-before-its-first-push` (#319) reaches the same blind
  row from the other side: a session that never pushed. Here the branch IS
  pushed (case B) and stays invisible, so this is not an instance of that
  node — the cause is the claim vocabulary, not liveness. The two together
  do say something that neither says alone: `orchestrate.md:190` *"branch
  merged (dispatch no longer lists it) → done. Nothing."* is literally true
  of a planner that was never listed and never will be.
- `rescope-re-offered-after-merge` (#317, issue #300) is the closest in
  SHAPE — a repair re-offered because the thing that would suppress it does
  not outlive the pass — and the mechanism is different (a ledger key that
  drifts when a holder merges, versus no suppression existing). Flagged
  because an answer pitched at the shape might cover both, and an answer
  pitched at this mechanism will not cover that one.
- `no-ceiling-on-one-item` (#317, issue #298): see candidate 4.

`urgency: normal`, argued rather than assumed: the money in this is the
consumer's reported five passes, and this session could not read a single one
of them. An `urgent` mark resting on numbers nobody here could re-count is
the failure the independent read on #317 caught twice. The harness-side
finding is real and cheap to sit on — the row costs nothing until an
orchestrator runs unattended. Canonical may raise it, and should, if it can
read the consumer's figures.

Note for a parallel wave: a research node has no `scope:`, so the overlap
guard cannot see that this node, `rescope-re-offered-after-merge` and
`plan-on-an-unmerged-branch` would all land in `dispatch`'s branch walks and
in `queue-context.sh`'s row builder. Taking two at once collides.

## Verification

**The second-context pass is IN FLIGHT as this commit lands, and this
section says only that.** `.claude/agents/verifier.md` at opus — the depth
`./joharness.sh review` names for this branch — was spawned on the node and
the branch diff with the claims above as its checklist: every citation
re-read at source, the uniqueness claim about the orchestrator's step 3
re-counted, the fixture rebuilt in its own directory and cases A–E
re-derived, every asserted grep count re-run including in a tree that
carries this node, and the sibling nodes on #317, #319 and #320 read for
duplication. It fixes nothing; it reports.

No claim above is marked GROUNDED, WEAK or UNGROUNDED yet, because nothing
has checked it from a second context. **This section is rewritten from what
that pass returns — the marks, what it read, and what did not survive —
before the retire commit, which is the last commit before the pull request
opens.** A node that reached a pull request with this paragraph still
standing would be the "Verification: Pending" breach the independent read on
#317 caught nine times; it is here for one commit so the node is not
untracked while the pass runs.

One mark can be made now, because no second context can change it: **the
consumer's eight commits, five planning passes and $15–25 per pass are
REPORTED and WEAK, and not re-measurable from here or by the verifier.**
`chrsctl/gx` is outside this session's reach (`add_repo` refused, GitHub
tools scope-limited) and a verifier subagent has no more reach than the
session that spawned it — the same limit #267 names. Marked so no reader
mistakes the citation for a measurement.

## Graduates to

[`.agents/docs/product/README.md`](../../.agents/docs/product/README.md) —
the file that already answers this question with the sentence an answer must
change: *"a requirement nobody has served is UNPLANNED, which is work, not a
candidate for this"*. Whatever canonical decides, the reasoning belongs
beside that clause and the two deletion paths it sits in, because the next
session to meet a requirement no plan can serve will read the rule, find it
decided, and re-open the question anyway if the why-explanation is not there.
A code change in `queue-context.sh` or a frontmatter field would be the
consequence; this is where the decision has to be legible.

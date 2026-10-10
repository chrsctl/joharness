---
research: guard-fires-on-an-empty-branch
urgency: normal
agent: opus
effort: high
graduates: .agents/harness/handover-guard.sh
---

<!--
Issue #296, reported from a consumer by the route
`.claude/commands/upstream-report.md` names. Canonical decides. The cost
measurement is about a session running the harness against real work and
could not be taken here; the guard's behaviour COULD be and was.
-->

## Question

Should `handover-guard.sh` add the `branch has no upstream` fact to a branch
that holds no commits and has a clean tree?

The two questions a NO forces — which ref the count reads, and what an
unreadable ref does — are under `## What would settle it`, because they are the
answer's shape rather than the question.

## Echo

The guard restates the finishing ritual from git facts at the moment a session
stops. Its own comment says what the unpushed fact is for — work *"invisible to
every other session"* — and the branch it fires on here has no work: zero
commits against the base, nothing in the tree. The `ahead` test two lines above
asks whether the branch holds anything; the `elif` the never-pushed branch falls
into asks only that the branch is not the base branch.

So the first half is not in dispute and I could reproduce it. What is NOT
settled, and is why this is a node rather than a one-line patch, is the second
half: a count needs a ref to count against, and the obvious one
(`origin/<base>`) is not always present. The issue's own proposed patch
swallows that case with `|| echo 0` and goes SILENT — which is the one
direction a guard must not fail, because the fact it drops is the fact it
exists for. Which ref, and what an unreadable ref does, is a decision about a
file every session stops through.

## Sweep

`goal-directed` — enough to establish whether the fact fires where nothing is
owed, whether the proposed remedy keeps the case the guard was built for, and
where that remedy fails. Not a survey of the guard's other facts, and not a
re-derivation of the ritual.

## What would settle it

The firing is settled by the pair in `## Findings`. What a session taking this
has to decide, and what closes each way:

- **Which ref the count reads.** `origin/<base>` is the fresh view and is what
  the rest of the guard's doctrine wants (facts, nothing inferred). A local
  `<base>` is always present in a normal checkout and can be stale. Settled by
  naming one and saying what it costs when it is wrong.
- **What an unreadable base does.** Two answers only, and they are opposite:
  FIRE (treat unknown as owed, accept a false positive in a rare state) or stay
  SILENT (accept losing the fact). The guard's header already takes a position
  on the general case — *"Never fails a session: anything unexpected exits 0
  with no output"* — and a reader has to decide whether a missing base ref is
  "unexpected" in that sense or is the ordinary state of a branch whose base
  was never fetched. Settled by a selftest case either way.
- **Whether a case lands in `.agents/harness/selftest/`.** The guard has
  incidents in its own header and the repo's position on a gate's false
  positives is emphatic elsewhere. A fix with no case for the empty branch is a
  fix that regresses silently.

Written before the two measurements below were taken: a remedy that silences
the empty branch and ALSO silences a branch holding unpushed commits has not
fixed the defect, it has removed the guard.

## Method

A fixture repository, not this one: the shape under test is a branch with zero
commits, and this repo's branches have commits. One origin, one commit on
`main`, pushed; then the shape the issue reports — a branch cut from `main`,
never touched, never pushed. The guard was run from THIS repo's copy at
`cb0028e` against that fixture through `CLAUDE_PROJECT_DIR`, so the code under
test is canonical's and only the git state is synthetic:

    HARNESS=<path to this checkout>
    git init -q --initial-branch=main bare-origin.git --bare
    git init -q --initial-branch=main work && cd work
    git config user.email a@b.c && git config user.name t
    echo hi > f.txt && git add f.txt && git commit -qm init
    git remote add origin ../bare-origin.git && git push -q -u origin main
    git checkout -q -b claude/empty-orchestrator-branch main

    printf '{"tool_name":"Stop","stop_hook_active":false}' |
      CLAUDE_PROJECT_DIR="$PWD" bash "$HARNESS/.agents/harness/handover-guard.sh"
    echo "EXIT=$?"

`$HARNESS` is spelled out because the guard resolves its own root from
`CLAUDE_PROJECT_DIR` and would otherwise read the fixture's missing copy of
itself; running it from the fixture directory is what makes the code under test
canonical's and the git state synthetic.

Then the same command four more times: after a `git commit` on that branch (the
real case), after `git checkout main` (the control), against a copy of the
guard carrying the issue's own proposed patch, and against that patched copy
with the base ref removed —

    git update-ref -d refs/remotes/origin/main

on a branch one commit ahead of the local `main`.

The source reads behind the claims about the rule:

    sed -n '69,78p' .agents/harness/handover-guard.sh
    sed -n '1,63p' .agents/harness/handover-guard.sh     # header, doctrine
    git grep -n "no upstream" -- .agents/harness

## Findings

- **The fact fires on a branch with zero commits and a clean tree.** Measured
  2026-10-08 against `cb0028e`, fixture above:

      ahead of main: 0  porcelain: []
      {"decision": "block", "reason": "Handover guard, git facts: branch has
      no upstream — git push -u origin HEAD. …"}

  The guard blocks the stop. `git status --porcelain` is empty and
  `git rev-list --count main..HEAD` is 0, so no fact about invisible work is
  available to be true. Controls, same fixture, same run: one commit on that
  branch still blocks (correct — that is the case the fact exists for), and the
  base branch itself is silent.

- **The rule is positional, and the code says so in four lines.** `cb0028e`,
  `.agents/harness/handover-guard.sh`:

      if [ -n "$remote_ref" ]; then
        ahead="$(git rev-list --count "${remote_ref}..HEAD" 2>/dev/null)"
        if [ -n "$ahead" ] && [ "$ahead" -gt 0 ]; then
          add_fact "${ahead} commit(s) not pushed"
        fi
      elif [ "$branch" != "$BASE_BRANCH" ]; then
        # Never pushed at all — invisible to every other session.
        add_fact "branch has no upstream — git push -u origin HEAD"
      fi

  A branch with a remote ref is asked whether it holds anything; a branch
  without one is asked only its name. The comment states the purpose the second
  test does not check.

- **The issue's proposed patch closes the false positive and keeps the real
  case.** The patch, as the issue gives it, replacing the two lines inside the
  `elif`:

      base_ahead="$(git rev-list --count "origin/${BASE_BRANCH}..HEAD" 2>/dev/null || echo 0)"
      [ "${base_ahead:-0}" -gt 0 ] && add_fact "branch has no upstream — git push -u origin HEAD"

  Measured 2026-10-08, same fixture, that patch applied to a copy of the
  guard: zero-commit clean branch, no output and exit 0; one unpushed commit,
  blocks carrying that fact (and, in this fixture, the workstream-file fact
  beside it, because the commit adds a file and no workstream file — the two
  are independent and the patch touches only the first). So the remedy is not a
  trade of one case for the other.

- **And it fails OPEN on a branch with commits when `origin/<base>` is
  absent.** Not claimed by the issue; measured 2026-10-08 after
  `git update-ref -d refs/remotes/origin/main` on a branch one commit ahead of
  the local `main`: the unpatched guard still blocks; the patched guard prints
  nothing at all. `git rev-list --count origin/main..HEAD` fails, `|| echo 0`
  makes it zero, and zero is read as "nothing owed". The branch in that state
  is exactly the one the fact was written for — commits that no other session
  can see — and the patch is the reason it is silent. How reachable that state
  is was NOT measured: a container cloned fresh has the ref, and a checkout
  fetched one branch at a time may not.

- **Reported, not re-measured here: the per-turn cost to one role.** The issue
  reports an orchestrator session in a consumer repo on 2026-10-07 blocked on
  every turn it ended from 19:34Z to 23:36Z, each needing one extra reply
  before the stop was allowed, because the guard is one-shot per stop. That is
  a second turn per orchestrator pass. The role holds no workstream file,
  commits nothing and pushes nothing by its own rules, so the state is not an
  accident of that run — it is what the role looks like every pass. Nothing
  here reproduces the turn count; the guard's behaviour on that state is what
  is reproduced above.

- **A selftest case for this fact ALREADY exists, and the patch keeps it
  green.** This node's own Method grep surfaces it and an earlier draft never
  mentioned it; the independent reader caught the omission.
  `.agents/harness/selftest/handover-guard.sh:396-400`:

      git -C "$sgwork" checkout -qb sgnew
      printf 'new\n' >"${sgwork}/new.txt"
      commit_all "$sgwork" "unpushed branch"
      out="$(guard "$JSON_STOP")"
      expect "never-pushed branch told to push" "no upstream" "$out"

  That fixture COMMITS before the stop, so it is the real case and the patch
  leaves it passing. Measured by the independent reader over a `git archive
  HEAD` copy, with and without the issue's patch applied, 2026-10-08:
  **2211 passed, 3 failed, 1 skipped both ways**, the same three failures each
  time (artifacts of running the suite inside a scratch copy — the
  leftover-process pair and the MANIFEST walk). So the patch regresses nothing
  the suite covers, and NOTHING in the suite reds for the empty branch. The
  third bullet of `## What would settle it` is therefore answered in one
  direction: a case exists for the fact, none exists for the case this node is
  about, and the fix owes the second.

- **The dirty-tree case is already covered and loses nothing.** `cb0028e`, the
  same file: `dirty="$(git status --porcelain … | head -1)"` adds
  `uncommitted changes in the tree` on its own, before the branch section runs.
  So a count-based gate on the never-pushed fact does not blind the guard to
  uncommitted work.

## Consequence for the queue

No plan is blocked on this and none carries a `research:` edge to it.

This node is one decision away from being a plan, and the decision is the
second and third bullets of `## What would settle it`. Whoever takes it should
expect to write the patch in one line and spend the time on the fail-open
direction and its selftest case — the reverse of how the issue reads.

Two things it must NOT become: a fix that widens into the workstream-file fact
below it (that one already fires only when the branch changes something), and a
fix with no case in `.agents/harness/selftest/`. The guard's own header carries
the incidents it was bought with, and a false negative here is invisible by
construction — nothing fires, nobody notices, and the work stays unpushed.

`.agents/harness/` is a protocol path (`./joharness.sh protocol-paths`), so the
branch that answers this is a human's.

## Verification

Second context: `.claude/agents/verifier.md` at opus, which built its OWN
fixture and took its own exit codes rather than reading the ones here — bare
origin plus a work tree, one commit on the base branch pushed, an untouched
branch cut from it, the guard run from this checkout through
`CLAUDE_PROJECT_DIR`. It also ran the full selftest over a `git archive HEAD`
copy, patched and unpatched, which this file's author did not.

- **The fact fires on a zero-commit clean branch** — GROUNDED. Reproduced
  independently, output matching including `ahead of main: 0  porcelain: []`.
- **The rule is positional** — GROUNDED. Four lines of shell, quoted byte-exact
  against source by both contexts.
- **The patch closes the false positive and keeps the real case** — GROUNDED,
  re-measured. The reader also found the quoted result incomplete: the
  one-commit case fires the workstream-file fact as well. Corrected here.
- **The patch fails OPEN with the base ref absent** — GROUNDED, and this is the
  node's novel claim. Re-measured from the reader's own fixture: unpatched
  blocks, patched prints nothing at all.
- **A selftest case already exists, and the patch keeps it green** — GROUNDED,
  and found by the second context, not the first. 2211 passed, 3 failed, 1
  skipped both ways, identical failures, all three artifacts of running the
  suite inside a scratch copy. An earlier draft of this file never mentioned
  the existing case although its own Method grep returns it.
- **The per-turn cost to one role** — WEAK. The issue's, not re-measurable
  here.

Standing limit on every claim below that came from the issue rather than from
this tree: `.claude/agents/verifier.md` declares `tools: Read, Grep, Glob,
Bash` and has no control-plane call, so a reported fleet reading can be
re-read against the issue and never re-sampled. That is issue #267, planned as
`docs/plans/verifier-cannot-read-the-plane.md`. Every such claim is marked
WEAK for that reason and not because anything contradicted it; the second
context did confirm each number against the issue it came from, and found no
invented one anywhere in this batch.

## Graduates to

`.agents/harness/handover-guard.sh` — the file whose test is positional, whose
header already carries the doctrine a reader has to weigh (facts only, never
fails a session), and whose `selftest/` neighbour is where the answer becomes
something that cannot regress. A rule line elsewhere would restate the
condition; the condition is four lines of shell and belongs beside them.

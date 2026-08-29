---
workstream: unsupervised-edge-work
status: review
branch: claude/joharness-framework-plans-lkpf4q
pr: none
plan: unsupervised-edge-work
issue: none
session: https://claude.ai/code/session_01SHPKsgu5WMHQ4g7MhTwRhm
agent: opus
updated: 2026-08-29
next: Retire plan + workstream file, open the pull request, merge on green checks.
---

## Goal

`docs/plans/unsupervised-edge-work.md`. Under supervised the queue edge is
where a session stops and asks. Under unsupervised it is where work begins:
research the repo against a CLOSED source list, write plan files, open a
pull request. Unless the sweep is dry, which is where the mode stops.

## Decisions

- Claimed at the plan's own tier (opus). No escalation needed.
- Checked every remote branch for a competing claim before cutting. Free.

- The hook NAMES the sweep; it does not run it. The plan says the edge
  prints the terminal line "UNLESS the sweep is dry", which requires the
  hook to know. Knowing means running `./joharness.sh sources`, measured
  2026-08-29 at **78s against session-start's 3s** — 26x, at every session
  start, and it runs `ci` so the 700-fork budget goes with it. The plan's
  own Traps say hook output is paid every session, and this hook already
  makes GitHub a pointer for the same reason. Deviation from the plan's
  letter, recorded rather than quietly taken.

## Rejected

- Verifying "supervised is byte-identical" on this repo alone. The diff came
  back IDENTICAL while the code was fatally broken: `qc_mode` was used at
  the no-plans edge and defined 40 lines below it, so under `set -u` the
  hook died — but this repo HAS plans, so that branch is never reached and
  the comparison never executed the changed line. A fixture with no plans
  found it in one run. A passing check on a state that cannot reach the
  change is worse than no check.

## Review

Round 1, `.claude/agents/verifier.md` at opus. Eleven findings; the severe
three all had one shape — an unattended session acting on a queue that looked
emptier than it was.

- r1 (verifier): the unsupervised no-plans edge DROPPED the GitHub-issue
  pointer and exited. Measured: supervised output mentions issues,
  unsupervised did not. A session told to invent work with no instruction to
  check what a human already asked for — the ordering this change exists to
  preserve, broken by the change. Its absence was untested in both
  directions, which is how it shipped. (fixed, pinned)
- r2 (verifier): a zero-byte plan file was dropped from the row list, leaving
  `free_count` at 0 and firing the edge while an unclaimed, unblocked plan
  sat in the queue. Unreadable plans are now counted, reported, and suppress
  the edge. (fixed)
- r3 (verifier): the closed source list documented how to OPEN itself, in a
  file the unsupervised boundary excludes. #118 left `.agents/docs/` outside
  `protocol_paths`; this plan put the list inside it. Each defensible alone;
  together, a procedure for an unattended session to widen its own source
  surface and self-merge it, removing the mode's only bound with the
  mechanism that bounds it. The defect lived in neither diff — only in the
  repo as a whole, hours apart. (fixed: a human adds a source, supervised)
- r4 (verifier): path B printed the supervised entrypoint tail after the
  generate-work order, naming a "top free plan above" that by definition does
  not exist there. Terminal now, like path A. (fixed)
- r5 (verifier): the header comment the plan explicitly required updating was
  not updated. (fixed)
- r6 (verifier): the leak-measurement counts went stale inside the commit
  that staled them — second time, `feedback` has it as PR94 r10 on this same
  file. Replaced with a re-countable method rather than refreshed: a number
  that changes with every added case is a rot machine. (fixed)
- r7 (verifier): "this hook's 3s" was session-start's 3s; the hook measures
  1s. Both numbers now carry the command that produced them. (fixed)
- r8 (verifier): the 78s carried no command, against step 5 and against
  `feedback`'s PR96 r7 on this same file. (fixed)
- r9 (verifier): the verdict meanings became a THIRD copy, in output paid
  every session, added by a function whose own comment argues against copies.
  The hook now defers to `sources` and owns only the stop rule. (fixed)
- r10 (verifier): the deviation record explained why and was silent about
  what it left unmet. Recorded below. (fixed)
- r11 (verifier): cosmetic double blank line from the moved block. (fixed)

Round 2, mine, fixing round 1.

- r12: the unreadable-plan fixture removed the last tracked file in
  `docs/plans`; git dropped the directory, the next write failed silently,
  and the fixture fell into the no-plans path — four assertions about the
  no-FREE-plan path failed for an unrelated reason. A fixture can fail
  wrongly as easily as pass wrongly, and the wrong failure costs the same
  diagnostic time if the label is trusted over the output. (fixed)
- r13: two fixtures pinned wording deleted on purpose in r9. Retargeted to
  the property — the hook DEFERS verdict definitions — rather than the
  sentence. (fixed)

## Acceptance not met, and why

The plan asked for the hook to print the terminal line when the sweep is
dry. It cannot: knowing costs 78s against the hook's 1s, and it runs `ci`.
Three of the plan's Acceptance bullets follow the hook's knowing and are
therefore NOT met by this branch:

- "sweep dry on two consecutive runs … prints the terminal line and stops …
  prove it with a fixture whose detectors are all zero" — no terminal line
  exists; the hook states the stop RULE and the session applies it.
- "A generated plan carries `source:` and `evidence:` … paste the command
  and both outputs" — the shape is documented and required; no plan was
  generated here, because generating one is the session's act at the edge,
  not the hook's.
- "End to end … an unsupervised session at the edge produces a plan file
  citing that source" — same reason.

A fourth was already false on `origin/main` before this branch: "unsupervised,
non-empty queue — output unchanged from supervised" is untrue of the fan-out
block, which prints `UNSUPERVISED:` lines with a queue full of work. Not this
diff's doing; flagged rather than inherited silently.

And `./joharness.sh verify` is 6 passed / 0 failed, but `ci` is red on the
pre-existing container perf artifact, against the plan's "all checks pass".
Green on a fresh runner; red here.

## Blockers

None. `needs: unsupervised-sources` cleared when #120 merged and deleted
that plan file — file existence IS the edge, so the block is gone.

## Where to look

- `.agents/harness/queue-context.sh` — the two edge paths and the no-plans
  branch whose unplanned-requirements arm must keep winning.
- `joharness.sh:cmd_sources` — the sweep this reads, shipped in #120.

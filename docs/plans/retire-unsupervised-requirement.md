---
plan: retire-unsupervised-requirement
urgency: normal
agent: opus
effort: high
needs: none
requirement: unsupervised-mode
scope: joharness.sh, .agents/harness/queue-context.sh, .agents/harness/handover-guard.sh, .agents/harness/AGENTS.md, .agents/harness/selftest/handover-guard.sh, .agents/harness/selftest/queue-context-supervised-only.sh, .agents/harness/selftest/queue-context-edge.sh, .agents/docs/unsupervised.md, docs/product/unsupervised-mode.md
---

## Goal

Direct ask 2026-09-03: does the repo still need the requirement inside
`docs/product/`. It does not, and the reason it cannot simply be deleted is
the finding.

`docs/product/unsupervised-mode.md` mixes two things with different
lifecycles. A SPEC that completes — eight `Satisfied when` bullets, of
which two are rules rather than conditions, four are conditions the harness
meets (two of those pinned by the suite, two field observations of live
runs that no test pins), one is false, and one is open — and PERMANENT
RULES that no completion retires. The rules have accreted 14 citations from running
code — 15, counted with an unfiltered `grep -rn`; an earlier draft said 14
and missed `joharness.conf` — four of them in output a session reads at the
moment it is told it crossed a boundary (`cmd_drain`'s NOT YOURS block, the session-start
banner, `lint_requirement_writes`, `handover-guard.sh`'s blocking fact).
Deleting the file alone points all four at nothing.

The spec is finished as far as this codebase can take it. Its one open
bullet — the fleet runs for hours — stopped being a claim about this
codebase when PR 202 made drain-only: a session takes one item and exits,
so the fleet's length is the heartbeat's, and the heartbeat is an operator
action with money attached that no session may take. That work is tracked
in issue #165, which already asks for the budget.

Two of the four Constraints are ALREADY in `.agents/docs/unsupervised.md`
— `## Authority: the prompt routes, the repository authorises` and
`## Not constrained, by decision` carry them in full. The requirement holds
second copies, which is the shape this repo says rots.

So: move the rules that live only in the requirement, repoint every
citation, delete the file.

This is the LAST PLAN of that requirement, and its pull request deletes the
requirement file with the plan file — the mechanism
`.agents/docs/product/README.md` names, and the reason this plan declares
`requirement: unsupervised-mode` rather than `none`. An earlier draft
declared `none`, which left the deletion resting on nothing but this file's
prose; a verifier round caught it.

What that mechanism does NOT settle, and this plan does not pretend it
does: the endurance bullet reads NOT shown, so "satisfied" here means the
harness has delivered everything it can, not that every bullet came true.
That is a reading, it is the requester's to accept or reject, and it is
flagged in the pull request rather than buried. The bullet itself is
rehoused verbatim in issue 165 so nothing is dropped either way.

## Scope

- `.agents/docs/unsupervised.md` — a new `## Bounds` section after
  `## The one stop`, carrying the three rules that exist nowhere else:
  protocol text is off limits to a session running unattended (with the
  SUPERVISED ONLY consequence and the two measurements the requirement
  carries for it); unsupervised merging uses the step 7 conditions
  unchanged; no unsupervised session writes a requirement, and `ci` reds
  the branch. `## Authority` and `## Not constrained` already carry the
  other two Constraints and are NOT touched — this plan removes a second
  copy, it does not make a third. Line 5's pointer at the requirement goes.
- `joharness.sh` — six citations repoint to
  `.agents/docs/unsupervised.md`, Bounds: the `JOHARNESS_MODE` usage row
  (~line 68), the protocol-boundary comment (~167),
  `lint_requirement_writes`'s comment and its printed line (~2481, ~2538),
  `cmd_drain`'s NOT YOURS block (~4697), the session-start banner (~5026).
  The last three are runtime output.
- `.agents/harness/queue-context.sh` — two comment citations (~193, ~240).
- `.agents/harness/handover-guard.sh` — the comment (~143) and the
  `add_fact` string a blocked session reads (~226).
- `.agents/harness/AGENTS.md` — step 2's markdown link (~52).
- `.agents/harness/selftest/queue-context-supervised-only.sh` — two
  comments: the one quoting the requirement (~104), and "The requirement's
  Acceptance: a supervised session cannot tell this shipped" (~79), which
  cites a section requirements do not have (they carry `Satisfied when`;
  `Acceptance` belongs to plans) and a promise the file will not be there
  to make.
- `.agents/harness/selftest/queue-context-edge.sh` — "its wording
  (byte-identical is the requirement)" (~137), citing a word the
  requirement carried. Both comments describe what their own cases assert,
  which stays true; only the attribution moves.
- `.agents/harness/selftest/handover-guard.sh` — the fail diagnostic
  telling a maintainer where to justify an unlisted tree (~352).
- `joharness.conf` — the `JOHARNESS_MODE` comment's pointer at the
  requirement, the citation an `--include`-filtered grep cannot see.
- `docs/product/unsupervised-mode.md` — deleted. `docs/product/` then holds
  no requirement, which is the honest state: the queue's remaining work is
  an operator's.

## Out of scope

- `.agents/docs/unsupervised.md`'s `## Authority`, `## Runs`,
  `## Heartbeat` and `## Not constrained` sections. They survive untouched;
  the Runs table is the endurance history and outlives the spec.
- Issue #165. It already carries the budget ask and the changed premise;
  this plan adds a comment saying the requirement retired, and changes no
  code for it.
- `lint_requirement_writes` itself, and every other gate. The rule it
  enforces survives the requirement's deletion — that is why Scope moves
  the rule rather than dropping it. No gate changes behaviour here.
- The requirement's second `Satisfied when` bullet, which a verifier round
  showed to be false at `== requirement authorship` and `authority`, and
  false before PR 202. It goes with the file. Named here so the disposal is
  deliberate rather than a convenience: this plan does not fix it, it
  deletes the file containing it, and if the human wants that bullet's
  claim enforced it comes back as a fresh requirement.
- `.agents/docs/product/README.md`'s requirement lifecycle. Unchanged: this
  retirement follows it — "satisfied" here means the harness has delivered
  everything it can, with the remainder re-homed in an issue.

## Acceptance

- `grep -rn 'docs/product/unsupervised-mode' .` excluding `.git` and this
  plan — no output. NO `--include` filter: an earlier draft filtered to
  `*.sh` and `*.md`, which made it blind to `joharness.conf`, the one file
  that was actually missed.
- `./joharness.sh ci` — `ci: pass`, `0 failed`; same under
  `JOHARNESS_MODE=unsupervised`.
- `./joharness.sh verify` — `0 failed`.
- `JOHARNESS_MODE=unsupervised ./joharness.sh drain` — reaches DRAINED
  (no requirement, no plan) rather than naming an unplanned requirement,
  and its NOT YOURS block, when a marked plan exists, cites a path that
  resolves.
- `git ls-tree --name-only origin/main docs/product/` after the merge —
  empty.
- Every rule that was in the requirement is findable:
  `grep -n 'off limits\|step 7 conditions\|writes a requirement' .agents/docs/unsupervised.md`
  returns all three.
- `./joharness.sh finish` — green; this plan and the workstream file
  deleted in the last commit before the pull request.

## Where to look

- The requirement itself is deleted by this plan, so read it from history
  rather than the tree:
  `git show 5e71e79:docs/product/unsupervised-mode.md` — Constraints, and
  the two bullets that are rules rather than conditions.
- `.agents/docs/unsupervised.md` — `## Authority` and `## Not constrained`
  already hold two of the four Constraints; the new section joins them.
- `joharness.sh:lint_requirement_writes` — the gate whose rule moves.
- `.agents/harness/handover-guard.sh` — `add_fact`, the message a blocked
  session reads.

## Traps

- Protocol text: `joharness.sh`, `.agents/harness/` and `.claude/` are in
  `protocol_paths`. Supervised session only.
- Do not make a THIRD copy. Two Constraints already live in the design
  doc; moving them again is the rot this plan exists to remove.
- The rules must survive the file. A citation repointed at a section that
  does not carry the rule is worse than the dangling path it replaced.
- Runtime output, not just comments: four sites print to a session. Check
  `drain`, `session-start`, `ci` and the guard's blocking fact by RUNNING
  them, not by grepping.
- `mkdir -p` before writing into `docs/plans` or `docs/handover`: git drops
  a directory when its last tracked file goes, and both are empty on this
  branch. A `cat >` into a missing directory fails silently into the gap —
  it cost this branch one commit already.
- Never delete a test to get green.

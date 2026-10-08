---
workstream: orchestrator-findings-2026-10-08-c
status: in-progress
branch: claude/orchestrator-findings-2026-10-08-c
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_011BJ7AKa5rQPF4xTF1MPdAh
agent: opus
updated: 2026-10-08
next: Write docs/research/a-requirement-no-plan-can-serve.md, spawn the verifier, retire this file, open the PR
---

<!--
Reporter session for a consumer (`chrsctl/gx`), route:
`.claude/commands/upstream-report.md`. One finding, one node, canonical
decides. Third of three reporter branches from the same consumer run; the
other two are PRs #319 and #320.
-->

## Goal

Turn ONE harness-flow finding from a consumer's orchestrated run into a
research node: `dispatch` re-offers a requirement as `UNPLANNED` on every
pass for as long as no plan on the base branch carries `requirement: <its
stem>`, and for some requirements no such plan will ever be written — so the
orchestrator keeps buying planning passes over one file. The node states the
question, the evidence and the candidate answers. It answers nothing and
changes no harness code.

## Decisions

- **One question, one node.** The brief named two adjacent facets. Facet (a)
  — a requirement-planning branch is invisible to `dispatch` — is evidence
  about the SAME loop (nothing suppresses a second planner), so it rides
  inside this node as a finding rather than becoming a second node. #319
  filed two nodes in one pull request and flagged that as a deviation; not
  repeating it.
- **`graduates: .agents/docs/product/README.md`.** The answer has to amend a
  sentence already written there — *"a requirement nobody has served is
  UNPLANNED, which is work, not a candidate for this"* (`:34`) — before any
  code moves. A rule line alone would lose the reasoning and the question
  would come back.
- **The consumer's own numbers are REPORTED, never re-measured.** `add_repo`
  for `chrsctl/gx` was refused in this session (auto-mode permission
  classifier) and the GitHub tools refuse an out-of-scope repository, so no
  gx commit, cost or dispatch output could be read. Every gx-side claim is
  marked REPORTED / WEAK with that reason named in-file. Every harness-side
  claim is measured here.
- **Measured with a fixture, not only greps.** Five cases (A–E) over a
  scratch repo with a real `origin`, including a CONTROL that changes one
  frontmatter field on the same branch. Greps alone could not tell a
  structural invisibility from a fixture artifact — and the first fixture run
  had exactly that artifact (below).

## Rejected

- **Marking the finding as a facet of #317's `no-ceiling-on-one-item`.**
  That node asks what bounds ONE manager's spend when every health signal
  reads healthy. The cost here is not one long manager: each planning pass
  is a separate session that terminates normally. A per-manager ceiling
  would not fire on any of them. Cross-referenced instead.
- **Folding it into #319's `a-manager-blocked-before-its-first-push`.** That
  node's session never pushed, so it has no ref and no row. Here the branch
  IS pushed and the row is still absent — measured, case B, with the control
  in case E. Different cause, same blind row; cross-referenced, not restated.
- **A fixture without a remote.** The first run never ran `git remote add
  origin`, so every push failed and the queue hook fell back to `HEAD`
  (`queue-context.sh:78`). The in-flight walk reads `origin/<branch>` refs,
  so "no row for the planning branch" was unfalsifiable in that run. Re-run
  with the remote; the result held, but it had to be re-taken to mean
  anything.

## Review

- r1: nothing recorded yet — the verifier runs once the node is written.

## Blockers

None. `chrsctl/gx` is unreachable from this session (above); that bounds what
the node may claim and is written into the node, not left as a blocker.

## Where to look

- `.agents/harness/queue-context.sh:644-655` — `served`, and the only test
  that silences a requirement row.
- `joharness.sh:8562-8572` — `dispatch`'s `UNPLANNED` row: no holder, no
  hold, no claim.
- `joharness.sh:7236` — `dispatch_retired_edges` skipping a branch because it
  "owns" a claim, which a `plan: none` workstream file does not.
- `.claude/commands/orchestrate.md:453-454` — the one step-3 spawn rule with
  neither an in-flight condition nor a ledger key.
- `.agents/docs/product/README.md:26-36` — the two deletion paths, and the
  sentence the answer must amend.

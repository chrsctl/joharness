---
plan: finding-lasting-record
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: joharness.sh, .agents/harness/selftest/review.sh, .agents/harness/selftest/orchestrated.sh, .agents/docs/manager-reference.md, .claude/commands/manager.md, .claude/commands/orchestrator.md, .agents/docs/glossary.md
---

## Goal

A verifier in consumer chrsctl/gx (PR chrsctl/gx#1169) found a real defect in
pre-existing code. The manager recorded it `wontfix: outside this plan's Goal,
pre-existing; sent as a lead`, and sent a lead naming a requirement stem that
dispatch does not list; the orchestrator dropped it, as orchestrator.md §4
says. No issue, no PR-body line: the finding lived only in a deleted
workstream file until a human filed chrsctl/gx#1173 by hand. Every finding
must land somewhere lasting — an issue or the pull request body — never only
in a workstream file or a lead.

## Scope

- `.agents/docs/manager-reference.md` § Lead — a finding about existing code
  outside the item is a defect (§ Defect: issue, or PR body); a lead is a
  heads-up to a live queue item only, never a finding's only record.
- `.claude/commands/manager.md` — the DEFECT / LEAD paragraphs point at that.
- `joharness.sh` — new `ci` stage `finding routes` (`lint_finding_routes`):
  a `## Review` finding with a `wontfix` verdict whose text says it is outside
  the item or pre-existing must cite `#<n>` or say `PR body`, else red.
  `finish` runs `ci`, so it gates the merge too.
- `.agents/harness/selftest/review.sh` — cases for the stage.
- `.agents/harness/selftest/orchestrated.sh` — text pins for the dropped-lead line.
- `.claude/commands/orchestrator.md` §4 / Report — a dropped lead still
  prints `unrouted lead <stem>: <text>`, sanitised as a kept lead.
- `.agents/docs/glossary.md` — only if a contested term appears.

## Assumptions

- A1: `ci` already folds `## Review` bullets and reads the branch's own (also
  retired) workstream files from git — evidence: `joharness.sh:lint_finding_markers`
  — confidence: high
- A2: `finish` runs `ci` — evidence: `joharness.sh:cmd_finish` — confidence: medium
- A3: orchestrator.md §4 drops a lead whose stem dispatch does not name and only
  "says so" — evidence: `.claude/commands/orchestrator.md:ONE LEAD PER LINE`
  — confidence: high

## Out of scope

- Editing chrsctl/gx: it gets this through its normal sync.
- The orchestrator posting issues or acting on a lead: it still never does.
- Core paths (`joharness.conf`, `.claude/settings.json`, `.github`).

## Acceptance

- `./joharness.sh ci` — `ci: pass`, with a `== finding routes` stage.
- `./joharness.sh verify` — 0 failed.
- The new selftest case fails with the stage removed from `cmd_ci`.

## Where to look

- `joharness.sh:lint_finding_markers` — the loop to copy.
- `joharness.sh:fb_marker` — what counts as a wontfix verdict.
- `.agents/docs/manager-reference.md:## Lead`
- `.claude/commands/orchestrator.md:ONE LEAD PER LINE`

## Traps

- Never skip, disable or quarantine a test to get green.
- No commit to a core path.

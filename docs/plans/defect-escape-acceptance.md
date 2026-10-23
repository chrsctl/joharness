---
plan: defect-escape-acceptance
urgency: normal
agent: opus
effort: high
needs: defect-block-resumes
requirement: defect-to-fix-loop
issue: none
scope: shared:joharness.sh, shared:.claude/commands/clerk.md, shared:.claude/commands/manage.md, .agents/docs/plans/README.md, .agents/docs/plans/TEMPLATE.md, .claude/agents/verifier.md, .agents/harness/selftest/review.sh
---

## Goal

`docs/product/defect-to-fix-loop.md`, clause 2. A fix that repairs only the
defect leaves open the door it came through. In gx, re-recording one
transcript fixed #806. Asking how it reached main found that #785 merged
with the audit red after its own verifier-fix commit, and that nothing in
local-mode `finish` runs the consumer's web suites. That produced a
consumer gate (gx#820) and a canonical report. The question has to be
part of every defect plan and checkable from git, not left to a session's
curiosity.

## Scope

- **The marker** is git-visible: the clerk writes an `## Escape` section
  into every plan it makes from a `defect:` issue. Plan readers find the
  section by heading, as `section_paths` already finds `## Where to look`.
  No issue title is read: neither the verifier nor `joharness.sh` can read
  one.
- **plans/README.md and TEMPLATE.md**: `## Escape` holds three questions.
  The manager answers them in the workstream file's `## Review`, one line
  each, each naming its command:
  - `- escape entry:` the merge that introduced the failure (bisect over
    first-parent merges, then along that branch), or `not bisectable:
    <why>`;
  - `- escape gate:` the check that should have caught it, and why it
    passed (not run, not in the merge gate, timing-dependent with the
    reason, asserted the wrong thing);
  - `- escape route:` this repo's gate → fixed in this pull request, or a
    plan file this pull request adds; canonical's gate → also a `## Review`
    finding naming the harness file, `wontfix: canonical's file`, which
    `./joharness.sh upstream` reports.
- **`./joharness.sh review`**: for a workstream whose plan has
  `## Escape`, print the three lines' state (present / missing). The edge
  gate (`pr:` set or status review/done) is red while one is missing. This
  is the clause-4 visibility for this step.
- **clerk.md §3**: write `## Escape` into a defect plan.
- **manage.md §4**: do not retire a plan with `## Escape` while `review`
  reports a missing escape line.
- **verifier.md**: on a plan with `## Escape`, check that each answer names
  its command, and that the route matches the gate's owner.
- **Selftest** (`.agents/harness/selftest/review.sh`): `review` is red for an `## Escape` plan with a missing
  `escape gate:` line and green with all three. It must fail without the
  change.

## Out of scope

- The block and resume mechanics (`defect-block-resumes`).
- Filing the report (`upstream-reporter-role`).

## Acceptance

- `./joharness.sh ci`: `ci: pass`, the selftest listed. The glossary and
  caveman lints are green.
- `./joharness.sh verify`: `0 failed`.
- `grep -n '## Escape' .agents/docs/plans/TEMPLATE.md .agents/docs/plans/README.md .claude/commands/clerk.md`:
  all three present.
- Consumer side: `.agents/scripts/sync-to-consumer.sh --dry-run <gx>`
  lists these files and no consumer-owned one.

## Where to look

- `joharness.sh:section_paths`, `joharness.sh:lint_plans_in_diff`, the
  `review` command.
- `.agents/docs/plans/README.md` Shape, `.agents/docs/plans/TEMPLATE.md`.
- `.claude/commands/upstream-report.md` §1 (how a harness finding is
  placed).

## Traps

- Docs state status quo: the gx story belongs in the pull request body,
  never in README or TEMPLATE (caveman.md, Status quo).
- "Flake" is not a gate answer: say why the check is timing-dependent.

---
plan: defect-escape-acceptance
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: defect-to-fix-loop
issue: none
scope: shared:.claude/commands/clerk.md, shared:.claude/commands/manage.md, .agents/docs/plans/README.md, .agents/docs/plans/TEMPLATE.md, .claude/agents/verifier.md
---

## Goal

`docs/product/defect-to-fix-loop.md`, clause 2. A fix that only repairs the
defect leaves the door it came through open. In gx, re-recording one
transcript fixed #806. Asking "how did it reach main" found two more things:

- #785 merged with the audit red after its own verifier-fix commit
  (`audit.mjs --scene dashboards-header`, bisected along the branch).
- Nothing in local-mode `finish` runs the consumer's web suites.

That question produced a consumer gate (gx#820), an urgent plan for a scene
a re-record cannot fix, and a canonical report. The question has to be
part of the plan, not left to a session's curiosity.

## Scope

- **`.agents/docs/plans/README.md`** and **`TEMPLATE.md`**: a plan with
  `issue:` naming a defect (title `defect:`) carries a `## Escape` section
  with three answers, each with the command that produced it:
  1. **Entry:** the merge that introduced the failure (bisect over
     first-parent merges, then along that branch). Or "not bisectable" and
     why.
  2. **Gate:** the check that should have caught it, and why it passed
     (not run, not in the merge gate, flaky, asserted the wrong thing).
  3. **Route:** gate owned by this repo → fixed in this pull request, or a
     new plan file added by it. Gate owned by canonical (a harness path) →
     a `## Review` finding naming the harness file, `wontfix: canonical's
     file`, so `./joharness.sh upstream` reports it.
- **clerk.md §3**: a defect plan's Acceptance includes the Escape answers.
- **manage.md §4**: a defect plan does not retire with an empty Escape.
- **verifier.md**: on a defect plan, check the Escape answers are measured
  and the route matches the gate's owner.
- **lint** (`joharness.sh:lint_plans`, if it reads sections): a plan
  whose `issue:` title is unknown to git cannot be told apart, so no lint.
  The rule lives in prose and in the verifier. Say so in the README.

## Out of scope

- The block and resume mechanics (`defect-block-resumes`).
- Filing the report (`upstream-reporter-role`).

## Acceptance

- `./joharness.sh ci` — `ci: pass` (glossary and caveman lints included).
- `grep -n '## Escape' .agents/docs/plans/TEMPLATE.md .agents/docs/plans/README.md`
  — both present.
- The README's Escape rule cites gx#806 → gx#820 as its measurement in
  one line, or none (status quo, no history), per caveman.md.
- Consumer side: `.agents/scripts/sync-to-consumer.sh --dry-run <gx>`
  lists the TEMPLATE and README changes and no consumer-owned file.

## Where to look

- `.agents/docs/plans/README.md` Shape, `.agents/docs/plans/TEMPLATE.md`.
- `.claude/commands/clerk.md` §3, `.claude/commands/manage.md` §4.
- `.claude/commands/upstream-report.md` §1 (how a harness finding is
  placed).

## Traps

- Docs state status quo: the gx story belongs in the pull request body,
  not the README (caveman.md, Status quo).
- "Flake" is not a gate answer: name why the check is timing-dependent.

---
plan: defect-escape-acceptance
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: defect-to-fix-loop
issue: none
scope: shared:.claude/commands/clerk.md, .agents/docs/plans/README.md, .agents/docs/plans/TEMPLATE.md
---

## Goal

`docs/product/defect-to-fix-loop.md`, clause 3. A fix that repairs only the
defect leaves open the door it came through. In gx, asking how #806
reached main found that #785 merged red after its own last commit, and
that local-mode `finish` ran no consumer check. That question led to a
consumer gate and to `local-finish-consumer-check`. It belongs in every
defect plan as three questions, answered where a reviewer reads them, with
no new machinery.

## Scope

- **plans/README.md and TEMPLATE.md**: an optional `## Escape` section,
  required in a plan the clerk makes from a `defect:` issue. Three
  questions, answered in the pull request body with the command behind
  each answer:
  1. **Entry**: which merge introduced it? Bisect, or say why not.
  2. **Gate**: which check should have caught it, and why did it pass?
  3. **Route**: a gate this repo owns is fixed in this pull request or a
     plan it adds. A gate canonical owns gets a `## Review` finding
     (`rN: … (wontfix: canonical's file)`) so `./joharness.sh upstream`
     reports it.
- **clerk.md §3**: write `## Escape` into a defect plan.

## Out of scope

- Any lint, `review` change or new `## Review` line shape. Answers live in
  the pull request body, so the finding lints never read them.
- Blocking and resuming (`defect-block-resumes`, `defect-resume`).

## Acceptance

- `./joharness.sh ci`: `ci: pass`.
- `grep -n '## Escape' .agents/docs/plans/TEMPLATE.md .agents/docs/plans/README.md .claude/commands/clerk.md`:
  all three present.
- Consumer side: `.agents/scripts/sync-to-consumer.sh --dry-run <gx>`
  lists these files and no consumer-owned one.

## Where to look

- `.agents/docs/plans/README.md` Shape, `.agents/docs/plans/TEMPLATE.md`,
  `.claude/commands/clerk.md` §3.

## Traps

- Docs state status quo: the gx story belongs in the pull request body,
  never in README or TEMPLATE.

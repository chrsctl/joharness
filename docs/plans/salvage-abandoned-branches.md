---
plan: salvage-abandoned-branches
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: docs/plans, docs/research
---

## Goal

Four unmerged branches carry workstream files with recorded findings and no
session that will act on them. `.agents/docs/product/README.md` says the salvage
route explicitly: "salvage plans from their workstream files, then delete (three
recovered exactly that way, 2026-08-21)."

Nobody has salvaged these. Their `## Review` sections hold 3, 4 and 8 findings
respectively, and those evaporate when a human eventually deletes the branches.

## Scope

- Read, without checking out, the workstream file on each unmerged branch the
  in-flight block lists (`git show <ref>:<path>`).
- For each finding or decision still true against today's `main`, file it as a
  plan under `docs/plans/` or a question under `docs/research/`, with the source
  branch and file named so the provenance survives.
- Write one summary listing every branch inspected and what came out of it, so a
  human can delete the branches knowing what was kept.

## Out of scope

- Merging, pushing to, or deleting any of those branches. They belong to other
  sessions; deletion is human-only and a session never `git push --delete`.
- Salvaging a finding that is already fixed on `main`. Check each against the
  current tree before filing it — a plan for work already done is worse than no
  plan, because the next session builds it again.
- Rewriting the findings. Carry them in their own words with the source named;
  a paraphrase loses the reasoning that made them worth keeping.

## Acceptance

- Every unmerged branch carrying an owned workstream file is named in the
  summary, with a verdict: salvaged into `<file>`, already fixed on `main`, or
  no longer applicable and why.
- Every filed node passes the plan or research lint (`ci` reds a node with no
  frontmatter since #143).
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.agents/harness/handover-context.sh` — the listing that names the branches
  and the `git show` command for each.
- `.agents/docs/product/README.md`, Branch flow — the salvage-then-delete route.
- `.agents/docs/research/README.md` — the shape a question must have.

## Traps

- A finding that reads important and is already fixed is the expensive mistake
  here. Check `main` before filing.
- Never `git push --delete`; the branches stay for a human.

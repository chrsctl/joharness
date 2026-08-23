---
description: Decompose work into a plan file the queue can hand to any session
---

Write a plan file under `docs/plans/`. Queue rules: `.agents/docs/plans/README.md`.
Reader is a literal agent (`.agents/docs/agent-selection.md`): executes what plan
says, precisely, nothing else. Ambiguity = executed wrong or asked back.
Inline — no subagent.

1. Name = short-kebab, the work not the branch. Copy
   `.agents/docs/plans/TEMPLATE.md` to `docs/plans/<plan>.md`.
2. Frontmatter, exact vocabulary (`ci` lints it):
   - `urgency`: `normal` | `urgent`.
   - `agent`: `haiku` | `sonnet` | `opus` — selection rules
     `.agents/docs/agent-selection.md`. haiku ONLY when mechanical AND fully
     specified AND every acceptance criterion runnable. One unclear
     edge = sonnet. opus when wrong-but-plausible code is the failure
     mode.
   - `effort`: `low` | `medium` | `high` | `xhigh`. xhigh when plan
     touches a Part 2 prohibition's territory.
   - `needs`: plan names whose RESULT this plan reads. Related-but-
     independent = fake edge, write `none`.
   - `requirement`: the one this serves (`docs/product/`), else `none`.
     Last plan of a requirement: say in Acceptance that its PR deletes
     the requirement file too.
   - `scope`: comma-separated path prefixes this plan will touch. Queue
     hook proves parallel safety from disjoint scopes — undeclared scope
     joins no wave. `none` only when touch-set genuinely unknowable.
3. Sections, all six:
   - **Goal** — why, requester's terms, one paragraph.
   - **Scope** — files to create or touch, named.
   - **Out of scope** — what a helpful agent would wrongly add. Named.
   - **Acceptance** — runnable commands WITH expected output. All pass
     or not done.
   - **Where to look** — `path:symbol` anchors into existing code. Open
     each; a wrong anchor costs the implementing session more than no
     anchor.
   - **Traps** — Part 2 prohibitions this plan can trip, one line each.
     Two plans touching one file: name each other here.
4. `./joharness.sh ci` — graph lint green (edges resolve, vocabulary
   holds).
5. Plans land on the base branch: direct push or small PR, human's call
   for requirements applies (`.agents/docs/product/README.md`).

$ARGUMENTS

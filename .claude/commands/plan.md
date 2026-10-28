---
description: Decompose work into a plan file the queue can hand to any session
---

Write a plan file under `docs/plans/`. Queue rules: `.agents/docs/plans.md`.
Reader is a literal agent (`.agents/docs/agent-selection.md`): executes what plan
says, nothing else. Ambiguity = executed wrong or asked back. Inline — no
subagent.

1. Name = short-kebab, the work not the branch. Copy
   `.agents/docs/plans/TEMPLATE.md` to `docs/plans/<plan>.md`.
2. Frontmatter, exact vocabulary (`ci` lints it):
   - `urgency`: `normal` | `urgent`.
   - `agent`: `haiku` | `sonnet` | `opus` | `fable` (rules:
     `.agents/docs/agent-selection.md`).
   - `effort`: `low` | `medium` | `high` | `xhigh`. xhigh when plan touches a
     Part 2 prohibition's territory.
   - `needs`: plan names whose RESULT this plan reads. Related-but-
     independent = fake edge, write `none`.
   - `requirement`: the one this serves (`docs/product/`), else `none`. Last
     plan of a requirement: Acceptance says its PR deletes the requirement
     file too.
   - `issue`: GitHub issue this plan turns into work (`/clerk` writes it),
     else `none`.
   - `scope`: path prefixes this plan will touch. Undeclared scope joins no
     wave. `none` only when touch-set genuinely unknowable.
3. Sections, all seven (`.agents/docs/plans.md`, Shape): Goal, Scope,
   Assumptions (`A<n>: <claim> — evidence: … — confidence: …`), Out of scope,
   Acceptance (commands WITH expected output), Where to look, Traps. Open
   each anchor in Where to look. Two plans touching one file name each other
   in Traps.
4. `./joharness.sh curate --apply`, then `./joharness.sh curate`: fix by
   hand what it still names on your plan (a `PROPOSE` line is the human's —
   say it in the pull request body).
5. `./joharness.sh ci` — graph lint green.
6. Plans land on the base branch: direct push or small PR, human's call for
   requirements applies (`.agents/docs/product.md`).

$ARGUMENTS

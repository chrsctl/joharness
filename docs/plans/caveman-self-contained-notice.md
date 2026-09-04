---
plan: caveman-self-contained-notice
urgency: normal
agent: haiku
effort: low
needs: none
requirement: none
scope: .agents/docs/caveman.md, .agents/NOTICE, .agents/harness/selftest/license-notice.sh
---

## Goal

Human asked, after #206: "Can we Attribute correctly". MIT's condition is
that the upstream's copyright notice AND its permission notice are included
in every copy. `.agents/docs/caveman.md` carries the copyright line and
points at `.agents/LICENSE` for the permission text, so a copy of the file
made without that neighbour is incomplete. Embed the permission text in the
file itself, so the attribution is complete wherever the file goes.

## Scope

- `.agents/docs/caveman.md` — a closing `## Upstream license` section with
  the MIT text verbatim under `Copyright (c) 2026 Julius Brussee`. Header
  keeps the citation and drops the "carry `.agents/LICENSE` with it" clause,
  which no longer applies.
- `.agents/NOTICE` — the caveman entry says the notice is reproduced in the
  file itself.
- `.agents/harness/selftest/license-notice.sh` — assert the permission
  text is present in `caveman.md`, both its grant sentence and its
  warranty disclaimer, so a later trim of the file cannot drop half of it.

## Out of scope

- Embedding the MIT text in `prior-art.md` or `graph.md`. Short quotations
  and adapted ideas carry no such condition; the NOTICE names the holders.
- Any change to root `LICENSE` or `.agents/LICENSE`.

## Acceptance

- `grep -c 'Permission is hereby granted' .agents/docs/caveman.md` — `1`.
- `grep -c 'THE SOFTWARE IS PROVIDED "AS IS"' .agents/docs/caveman.md` — `1`.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- SHIPS: `caveman.md` reaches every consumer at its next sync. Consumer-side
  check: the two greps above in the consumer tree after `upgrade`.

## Where to look

- `.agents/harness/selftest/license-notice.sh` — the existing copyright-line
  assertion; the new ones sit beside it.
- `LICENSE` — the MIT text to reproduce, holder line swapped.

## Traps

- The permission text is byte-exact MIT; caveman style never touches it.
- Retire this plan and the workstream file in the last commit BEFORE the
  pull request opens.

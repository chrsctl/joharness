---
plan: spawn-bullet-names-checkout-cost
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: .claude/commands/orchestrate.md
---

## Goal

A consumer orchestrator (chrsctl/gx, 2026-10-14) spawned 5 managers with
`create_session` and no `source_url`. The page already says `source_url`;
it does not say what leaving it out costs, so the orchestrator learned it
from stranded sessions: 2 of the 5 never started, one item sat unclaimed
about 40 minutes and spent one of its two respawns. Put the consequence
beside the clause, so an orchestrator reading its own spawn bullet learns
why `source_url` is a rule. The answer comes from the retired research node
`spawn-without-checkout-strands-manager`; recover it with
`c=$(git log -1 --format=%H --diff-filter=D -- docs/research/spawn-without-checkout-strands-manager.md)`
then `git show $c^:docs/research/spawn-without-checkout-strands-manager.md`.

## Scope

- `.claude/commands/orchestrate.md` — Manager spawn bullet (the one opening
  `- Manager: \`create_session\` with \`source_url\``): add ONE sentence
  after the `clone_depth` clause stating the consequence, in substance:
  without `source_url` the session starts in an empty `/home/user` with no
  checkout and no `/manage` (repo skills load only once a repo is attached),
  and a manager cannot be relied on to attach the repo itself — measured,
  one self-attach succeeded and one was denied at `git clone`. So a spawn
  without it is a spawn that may never claim.
- Same file, hand-off step 3 (`create_session`: `source_url` = ...): point
  at the Manager bullet's sentence in at most one clause ("same cost as a
  manager spawn without it") — the successor orchestrator strands the same
  way. Not a second copy of the sentence.

## Out of scope

- Any change to `joharness.sh`, `dispatch`, or the health pass (e.g. a check
  that flags a spawn tagged `config:no-git-repo`). The research node found a
  wording gap, not a tooling defect; a detector is a separate plan if ever.
- The spawn prompt text (`/manage <path>` + standard lines). Adding
  "if no checkout, `add_repo` and clone" to it was measured unreliable
  (auto-mode classifier denied the clone in one of two sessions).
- Any other page, rule line in `AGENTS.md`, or the glossary.

## Acceptance

- `grep -c 'source_url' .claude/commands/orchestrate.md` — 2 or more, and
  the Manager bullet's paragraph contains the words `empty` and `/manage`.
- `./joharness.sh ci` — `ci: pass`. This is the check a consumer runs at its
  next sync: the page ships to every consumer.
- `./joharness.sh verify` — `0 failed`.
- `git diff --stat origin/main` — `.claude/commands/orchestrate.md` plus the
  plan and workstream file deletions only.

## Where to look

- `.claude/commands/orchestrate.md:Manager` — the spawn bullet; `source_url`
  is its first clause.
- `.claude/commands/orchestrate.md:hand-off` — step 3 spawns the successor
  with the same `source_url` clause.

## Traps

- `.claude/settings.json` and `.github` are core paths
  (`./joharness.sh protocol-paths`); `.claude/commands/` is not — do not
  widen into a core path.
- Caveman style (`.agents/docs/caveman.md`): one sentence, rule plus
  consequence; the measured story stays in this plan's Goal and the PR body.
- Contested terms have one spelling (`.agents/docs/glossary.md`); `ci`
  fails on the others.

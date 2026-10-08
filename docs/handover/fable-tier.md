---
workstream: fable-tier
status: in-progress
branch: claude/fable-tier
pr: none
plan: fable-tier
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: sonnet
updated: 2026-10-08
next: Edge review recorded; run ci, retire, open the pull request, merge
---

## Goal

`docs/product/scout-role.md`, first bullet: the Lineup gains a fourth tier
`fable`, bound to judgement roles and never a build. Today `agent: fable` is
a red `ci`. This lands the vocabulary and the bound; the roles using it are
`scout-cycle` and `scout-command`. Supervised session at the human's ask
(protocol text: `joharness.sh`, `.claude/commands`).

## Decisions

- Session runs above the plan's tier (sonnet): escalation is allowed, and
  the human asked this session to drain the supervised queue continuously.
- A fable plan with NO `scope:` is red too, its own line: the bound reads
  the declaration, and absent proves nothing. The plan names only the
  outside-the-prose-dirs case.
- Scope parsed by `scope_norm`, split out of `curate_scope_list`: one
  normalization of `scope:`, not a second reader. `shared:` entries count by
  their path.
- Followed the planning-manager tier to every place it is spelled, not only
  the two the plan names: `dispatch`'s UNPLANNED row, agent-selection's
  "role-fixed tier" bullet, orchestrate's "for an opus planning manager"
  line, and the loop-respawn escalation ("already opus or fable = the tier
  stays") — else a looping fable manager had no defined next tier.

## Rejected

## Review

- r1: (verifier) `lint_fable_bound`: `scope: docs/../joharness.sh` matched `docs/*` and was green — a building fable plan passed. (fixed — an entry with a `..` segment or an absolute path is red; selftest case)
- r2: `/code-review`: `scope_norm` splits on commas only, so `scope: docs/x.md joharness.sh` (or `;`) read as one path under docs/ and passed. (fixed — entries split again on blanks and `;`; selftest case)
- r3: `/code-review`: fable had no rank, so "session below the plan's tier" and "escalate, never downgrade" could not compare it with opus, and a fable session could take a build plan as an escalation. (fixed — agent-selection states haiku < sonnet < opus < fable, fable off the build ladder)
- r4: `/code-review`: `.claude/commands/plan.md`, `.agents/harness/AGENTS.md` and the research README still spelled the vocabulary as three tiers. (fixed — all three name fable)
- r5: `/code-review` + (verifier): orchestrate's closed spawn-prompt list gave "Run at effort xhigh." to an escalated opus successor only, not a fable one. (fixed)
- r6: `/code-review` + (verifier): `scope: none` on a fable plan was red as "no scope", though `none` is the explicit touches-nothing declaration, and the doc named only the reaches-past red. (fixed — `none` passes, absent stays red, both written in agent-selection)
- r7: `/code-review` + (verifier): the rc check could not tell the bound from unrelated red, the green side never checked `ci` exit, and two pins still spelled three tiers. (fixed — green state asserts rc 0, pins name fable)
- r8: `/code-review`: the cover test duplicated `curate_covered`. (fixed — the bound calls it)
- r9: `/code-review`: `next:` stale and `## Review` empty after the build commit. (fixed — this section, and `next:`)
- r10: (verifier) pricing 10 / 50 and the ID `claude-fable-5-1` are UNVERIFIED from the checkout. (no change — the plan cites the claude-api skill, 2026-10-06, and the row carries that source and date)

## Blockers

None.

## Where to look

- `joharness.sh:lint_enum` call sites — `grep -n 'haiku sonnet opus'`.
- `joharness.sh:review_recipe` — tier to recipe.

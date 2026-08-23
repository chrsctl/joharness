---
requirement: pr-steward-skill
priority: normal
---

<!-- Proposed by extensions-research session 2026-08-23. Merge = ratify. -->

## Goal

Loop's Finish step measured weakest at far edge: three dead branches left
standing 2026-08-21, plan files undeleted, read as in-flight work. Claude
Code remote sessions driving or watching a PR read
`.claude/skills/steward/SKILL.md` from the PR head branch before acting on
CI and review events — platform convention. Put harness finish rules where
that reader already looks: `./joharness.sh ci` before every push; review
churn rule; merge = DELETE remote branch; PR final state deletes plan file
(+ requirement when last plan) + workstream file; merge commits, never
rebase, on shared branches.

## Satisfied when

- `.claude/skills/steward/SKILL.md` exists. Caveman. Rules restated with
  pointers to why-docs; nothing contradicts `harness/AGENTS.md`.
- Ships to consumers: `.claude/skills` added to sync DIRS list, selftest
  proves the path syncs.

## Constraints

- Restatement only — no new rule the Loop does not already state. Two
  sources disagreeing is worse than one source unread.

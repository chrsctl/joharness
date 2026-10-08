---
workstream: orchestrator-findings-2026-10-08-d
status: in-progress
branch: claude/orchestrator-findings-2026-10-08-d
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_011gvC8GiNBVUPpsRjA7XA2Q
agent: opus
updated: 2026-10-08
next: Measure the guard against both spellings, write both research nodes, retire this file in the last commit before the PR, open the PR, run ci
---

## Goal

Reporter session. Turn two harness findings a consumer (`chrsctl/gx`) recorded
into research nodes on this repo's queue, one pull request, no merge — the
human merges. The findings are in the retired workstream file of the gx
manager that fixed `main`'s `crm` job step 11 (gx PR #520, merge `7afe8ed3`):
`git show 9c69b8e9:docs/handover/crm-c4-registry-agreement-after-512.md`,
`## Review` entries r1 (harness) and r2 (verifier, process).

Both were routed rather than fixed there, for the same reason: the files they
name are under `./joharness.sh protocol-paths`, which a manager session may
not commit to. This repo is where they land.

## Decisions

- **Two nodes, not one.** They share only their origin. F is a text-matching
  gate that refuses one spelling of a shape and allows another; G is about
  which reader of the harness owns a rule that exists nowhere. Different
  evidence, different graduation targets, and either answer leaves the other
  question exactly as open.

## Rejected

- (none yet)

## Review

Pending step 5.

## Blockers

None.

## Where to look

- `.agents/harness/pretool-bash-guard.sh:judge` — F lives here; the self-match
  deny is keyed on the TOOL, inside the one check that runs before the bound
  checks.
- `.agents/docs/subagents.md` — G's candidate home; already owns "all of them
  share the parent's container".

---
workstream: verifier-cannot-read-the-plane
status: in-progress
branch: claude/verifier-cannot-read-the-plane
pr: none
plan: verifier-cannot-read-the-plane
issue: none
session: https://claude.ai/code/session_01JXryjCKHhwkN7Xrv1qXz55
agent: sonnet
updated: 2026-10-08
next: Add the outside-this-checkout limit to verifier.md and research README Verification, assert both in review.sh.
---

## Goal

Issue #267, option 1 only: the verifier has Read, Grep, Glob, Bash and no control-plane call, so a claim resting on a reading outside this checkout is one it can only check for internal consistency. Say so in verifier.md, have research nodes name their second context up front in Method, and pin both with one shared literal. Supervised-only plan, supervised session at the human's /drain, 2026-10-08.

## Decisions

## Rejected

## Review

## Blockers

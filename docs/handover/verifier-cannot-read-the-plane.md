---
workstream: verifier-cannot-read-the-plane
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: none
issue: 267
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: sonnet
updated: 2026-09-17
next: Review the plan, then retire this file and open the pull request
---

## Goal

Issue #267, decomposed. Loop step 2: nothing builds unplanned, an issue
becomes a plan before code, and the decomposition IS the work. The issue is
that `.agents/docs/research/README.md` requires a second context while Loop
step 5 spawns a reviewer with `tools: Read, Grep, Glob, Bash` — so a
question whose evidence is a control-plane record cannot be verified by the
reader this repo provides.

## Decisions

- `plan: none` in the frontmatter and `issue: 267` set. This work writes a
  plan; it does not implement one, so naming a plan it does not hold would
  tell the queue that plan is taken.
- ONE option becomes the plan, not three. The issue's option 1 — say the
  limit out loud — is free and independent. Options 2 and 3 are decisions
  about what an unattended agent may do to a live fleet and about making a
  question wait on a person; both are the human's, and the issue declines to
  claim either. Named in the plan's Out of scope with the reason, so the
  next session does not quietly decide one by building.
- The plan asks for the TWO files to agree mechanically on which claims are
  affected. The node author reads one file and the reviewer reads the other,
  so a narrower sentence in one is exactly the drift that produced the
  instance — the same shape as the closing-report field two items ago.

## Rejected

- Building option 1 directly instead of writing the plan. It is two
  sentences and a test, so the temptation is real, and it is the rule the
  Loop states without a size exemption: small ask, small plan, still a plan.
  The plan is also where the two-files-must-agree acceptance gets written
  down, which is the part a session doing this from the issue alone would
  miss.
- Issue #266, claimed and live. Its branch
  `claude/worker-idle-detection-l3v9m3` carries a workstream file naming it,
  and `get_session` on that session at 2026-09-17T14:01Z reads
  `SESSION_STATUS_RUNNING`, connected, `updated_at` inside the minute. Not
  mine, and not edge work either — no `pr:`, status in-progress.
- Issues #249, #251, #254 and #258. Their buildable parts are already in the
  queue as the plans and research filed in pull request #262, two of them
  since built; what remains in each is a human's decision, recorded on the
  issue.
- `docs/plans/orchestrated-run.md`, the queue's first plan. Blocked on the
  human's heartbeat and on run 3 having stopped.
- The edge branch naming pull request #10. Re-read from GitHub this session:
  closed, unmerged, since 2026-08-21.

## Review

## Blockers

None.

## Where to look

- `.agents/docs/plans/README.md` — plan shape and the `scope:` rules.
- `.claude/agents/verifier.md:4` — the tool list the issue is about.

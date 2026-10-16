---
workstream: heartbeat-self-registers
status: in-progress
branch: claude/heartbeat-self-registers
pr: none
plan: heartbeat-self-registers
issue: none
session: https://claude.ai/code/session_01XeXyvPqHBEa67tQe5q8JrV
agent: opus
updated: 2026-10-16
next: Re-run ci and verify on the review fixes, then open the PR
---

## Goal

Requester: the heartbeat registers itself when `/orchestrate` runs and none
exists. Keeper design chosen by the requester in this session.

## Decisions

- Bound to a keeper session, not fresh-session: a session-made
  fresh-session Routine fires with `sources: []` and no session or GitHub
  tools (transcript of `session_011K3RWr1Ypfqu4z8XiW5CyX`, 2026-10-16).
- Keeper liveness = a pending `/orchestrate pass` wake bound to an
  `orchestrator: <owner/repo>` session. A RUNNING orchestrator mid-pass has
  no pending wake; the spawned one's step 3 exits on it, one short session.
  `list_sessions` rejected for the keeper: ~78K characters per call, hourly,
  into one persistent context.
- A paused heartbeat (`enabled` false, empty `ended_reason`) is the human's
  veto: never re-enabled, never replaced.

- The successor plan's IDLE-with-`updated_at` step 3 rule dropped: the
  keeper reads pending wakes, so an orchestrator between passes is seen.

## Rejected

- Session-made fresh-session heartbeat: measured unable to orchestrate.

## Review

- r1: (verifier) keeper liveness assumes list_triggers lists other sessions' wakes (no change: measured account-wide 2026-10-16, gx wake bound to session_012MPaDckrAwxqsiu5aMwKKs listed from this session; recorded in orchestrated.md and Keeper step 2)
- r2: (verifier) two orchestrators starting together both exit at step 3 (fixed: the older RUNNING one proceeds, the newer exits)
- r3: (verifier) duplicate heartbeats deadlock the restart (fixed: same tie-break; duplicates stay report-only)
- r4: (verifier) replace deletes before the lineage check (fixed: lineage check first; re-rooting documented)
- r5: (verifier) a UI-made Routine could be deleted if it reads meta_mcp (fixed: replace only prompt exactly /orchestrate keeper; unmeasured stated)
- r6: (verifier) pause detection rests on an empty ended_reason (fixed: any ended_reason but auto_disabled_session_gone counts as paused)
- r7: (verifier) pausing does not stop a running chain (fixed: wording says hourly restarts; human stop also pauses the heartbeat)
- r8: (verifier) the joharness Routine under another name is ignored (no change: never counts, never touched, now stated in the Stop bullet)
- r9: (verifier) REGISTER spawns one redundant orchestrator, chaining registrations (fixed: an exiting duplicate's step 5 is report-only)
- r10: (verifier) keeper copies the registering session's model (fixed: Lineup sonnet for keeper and its orchestrators)
- r11: (verifier) keeper depth stated as fact, plan lists it unmeasured (fixed: cited the create_session lineage reading)
- r12: (verifier) successor plan starts a duplicate on a pending wake; needs none (fixed: liveness check kept; needs heartbeat-self-registers)
- r13: (verifier) 78K figure unsourced (fixed: 77,897 characters at limit 30, 2026-10-16)
- r14: (verifier) keeper drops the Tools ABSENT rules (fixed: Tools applies; no list_triggers creates nothing)
- r15: (verifier) a UI-deleted heartbeat leaves its keeper (fixed: REGISTER archives stale keepers first)
- r16: (verifier) old-spec UI Routine gets no migration path (fixed: stale line names delete it)
- r17: (verifier) needles miss cadence, candidate filter and more (fixed: 16 needles added; mutation run of three clauses failed as expected)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md` "## 0. Start" step 5, "## Keeper".

---
workstream: liveness-in-a-long-turn
status: in-progress
branch: claude/drain-8jr601
pr: none
plan: liveness-in-a-long-turn
issue: none
session: https://claude.ai/code/session_01K6sHM4RWyYDCLZmrDSrWk3
agent: opus
updated: 2026-09-17
next: Retire the workstream file and open the pull request; the research node stays OPEN on main
---

## Goal

`docs/research/liveness-in-a-long-turn.md`. Does a session's `updated_at`
advance while it sits inside ONE long turn, or only when a turn ends? The
health pass decides kill, nudge and respawn from `updated_at` plus the
branch head, and two rules drafted for issue #249 assumed OPPOSITE answers
in the same diff. Four rules were withdrawn pending this. A wrong answer
destroys work in progress and spends the concurrency cap twice.

## Decisions

- The corpus is the live orchestrated fleet, sampled read-only from here
  with `get_session`. The node's Method asks for a session whose turn length
  is known independently and a sampler that is not the session itself; both
  hold, and it costs nothing, where spawning a session to observe would be
  money for a reading already available.
- The independent discriminator is `post_turn_summary`, not my judgement of
  what a manager is doing. It is written when a turn ENDS, so `updated_at`
  moving while `post_turn_summary` is byte-identical means no turn boundary
  fell between the samples. That closes the confound the node does not name:
  many short turns look like one long turn if you only watch `updated_at`.

## Rejected

- Spawning a session with a deliberately long task, which is what the node's
  Method sketches. It is the cleaner experiment and it costs the human money
  for an observation the running fleet already offers. Recorded rather than
  silently skipped: if the fleet reading comes back ambiguous, that spawn is
  the next step and it is an operator decision.
- `docs/plans/orchestrated-run.md`, the queue's first item. Blocked on the
  human's heartbeat and on run 3 having stopped.
- The edge branch naming pull request #10. Re-read from GitHub this session:
  `state: closed`, `merged: false`, closed 2026-08-21.

## Review

The answer was drafted, graduated, and then WITHDRAWN on review. Seventeen
findings from the second context; the five that decided it:

- r1: (verifier) `## Verification` recorded a second context re-sampling the
  subjects, and the agent it names cannot: `.claude/agents/verifier.md`
  declares `tools: Read, Grep, Glob, Bash`, no control plane. I asked it for
  a call it has no tool for and wrote the outcome down before it answered.
  (fixed — the section now says what it could and could not do, and every
  reading is marked from what it actually checked.)
- r2: (verifier) the same section GRADED my own claims GROUNDED before any
  second context reported, which is the one thing the research protocol
  exists to stop. (fixed — the marks are the second context's, and three of
  them moved: WEAK, WEAK, UNGROUNDED.)
- r3: (verifier) leg 1's premise — no `post_turn_summary` means no turn
  ended — is contradicted by this repo's own health-pass notes, which record
  a session with no summary whose `status_bucket` read `REVIEW_READY` and
  conclude the field's authorship is unestablished. And subject A carried
  `external_metadata.last_served_model` PRESENT at every sample, which the
  same page reads as a turn having been served. I had that field in front of
  me and did not read it. (fixed — leg 1 is WEAK, and the field set to record
  at every sample is named in Method.)
- r4: (verifier) the graduated sentence dropped the "on a connected session"
  qualifier, and subject C is its counter-example: frozen, disconnected, and
  nowhere claimed to be dead. Shipped, it would have licensed killing an
  idle manager that had armed its own check-in — the shape the graduation
  target already records costing a duplicate manager and money. The new
  selftest pinned the unqualified string, so the qualifier could not have
  been restored without editing the test. (fixed — the graduation is
  reverted; `.claude/commands/orchestrate.md` and the topic file are back at
  `origin/main`.)
- r5: (verifier) the graduated sentence said the field was observed
  advancing across 11m52s. It was observed across 7m27.9s; the leading
  4m24s is `created_at`, not an observation — a 37% overstatement of the
  number it printed. (fixed with r4, and the Findings now separate the two
  spans.)
- r6: (verifier) a consumer's item name was quoted verbatim in the research
  file, from a subject's `task_summary`. The requester's standing rule and
  `.agents/docs/consumer-repos.md`, "Name no consumer", which covers a
  consumer's item names. Second time this session, and this one reached
  `main` for as long as it took to catch. (fixed — the quote is gone; the
  finding it supported does not need it.)
- r7: (verifier) the Method block recorded one line of calls for a run that
  made six, and its stated first time was a `list_sessions` page, not a
  `get_session` — so the file's own numbers contradicted its claim that
  every reading came back within a second of its call. The session ids were
  recorded nowhere at all, and they are opaque tokens the naming rule does
  not cover, so nobody can re-sample the subjects. (fixed — Method says what
  a reader can repeat and admits the run itself is not repeatable, which is
  cheaper than a claim nobody can test.)
- r8: (verifier) the disconnected control cannot separate read-bumping from
  a connection heartbeat, because a disconnected session is frozen either
  way — so it rules out nothing where the confound bites. It named the
  better control, free on the same fleet: an IDLE but CONNECTED session read
  twice through `list_sessions` only. (fixed in the file — that reading is
  the named next step, and it decides both open confounds at once.)

## Blockers

None.

## Where to look

- `.claude/commands/orchestrate.md`, the evidence table and the health rows
  — where the answer graduates, and where a wrong one costs money.
- `docs/research/liveness-in-a-long-turn.md` — the question, and what it
  says would settle it either way.

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
next: Take read 2 through list_sessions ONLY, at least 5m after 16:43:50Z, and compare the two subjects' updated_at to the microsecond
---

## Goal

`docs/research/liveness-in-a-long-turn.md` names ONE reading as its next step
and says nobody has run it: take a session that is IDLE but still
`connected`, read it twice several minutes apart through `list_sessions`
ONLY, and compare `updated_at`. Frozen kills the read-bumping confound;
moved with no `get_session` between means the field is a connection
heartbeat and movement is not progress. Both of the node's open confounds
turn on that one reading, and the fleet that produces such sessions is live
right now.

## Decisions

- **`list_sessions` only, and a subject no `get_session` has touched.** The
  method is explicit. I called `get_session` once this session, on an
  orchestrator session, to re-derive whether an unrelated queue item was
  actionable — so that session is disqualified as a subject and is not one.
  The two subjects below appear only in `list_sessions` pages.
- **Two subjects, not one.** Both IDLE and connected at read 1, with
  `status_bucket` differing (`REVIEW_READY` and `COMPLETED`), so a frozen
  result is not an artefact of one bucket.
- **The disconnected rows are kept as the contrast the node says it lacks.**
  Read 1 carries 26 of them with the full field set, so the
  connected/disconnected comparison no longer rests on one subject.
- **Session ids are recorded; titles are not.** The node already rules that
  ids are opaque without the fleet and so are not a consumer's name. The
  titles in these rows ARE item names and stay out.

## Rejected

- Nothing yet.

## Review

- (none yet)

## Blockers

None.

## Where to look

- `docs/research/liveness-in-a-long-turn.md`, `## Consequence for the queue`
  — the reading, and what each outcome settles.
- `.claude/commands/orchestrate.md`, step 2's evidence table — where this
  graduates when it closes, and the line eighty lines below it that calls
  the question unmeasured.

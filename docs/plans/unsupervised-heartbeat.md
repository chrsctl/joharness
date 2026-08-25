---
plan: unsupervised-heartbeat
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: unsupervised-mode
scope: .agents/docs/unsupervised.md
---

## Goal

Fan-out makes the fleet wide. Nothing yet makes it long. Each spawned
session claims a plan, merges it and ends, so the fleet survives only while
every generation successfully spawns the next — and one generation that
fails to spawn ends it silently, with the queue simply not draining and the
repo looking idle rather than broken. The requirement asks for hours
unattended; a chain with no restart cannot promise that.

This plan adds the clock. A durable scheduled Routine fires a fresh session
on an interval; that session reads the queue and acts. It holds nothing in
a container, so nothing it depends on can be reclaimed, and it re-seeds the
fleet whether or not the previous generation finished cleanly. Mechanism
comparison behind this choice, including the four rejected candidates:
`.agents/docs/unsupervised.md` (written by this plan).

## Scope

- `.agents/docs/unsupervised.md` — new, and the whole deliverable. The
  heartbeat is agent-side tooling, not shell: `joharness.sh` cannot create
  a Routine, so what ships is the procedure a session follows plus the
  reasoning that fixes it. Contents: which mechanism and why; what the
  firing session is told; how it decides between running a plan itself and
  fanning out; how an operator inspects, pauses and deletes the Routine;
  and what happens when a firing lands while the previous fleet is still
  working.
- The same file carries the rejected alternatives with their disqualifying
  detail, so the next session does not re-litigate: session-scoped cron
  dies with the session that created it; a self-scheduling single session
  is the same broken chain with less width; GitHub Actions works but needs
  a credential decision from a human and a PAT, because a pull request
  opened by a workflow gets no CI runs; an external Ralph-style loop needs
  a host that stays up, which an ephemeral container is not.

## Out of scope

- Creating the Routine. That is an operator action with a real cost
  attached, and the harness documents it rather than performing it. A
  session that creates a recurring job because a plan told it to has
  started spending money nobody approved.
- Any shell in `joharness.sh` or `.agents/harness/`. Scheduling is not the
  entrypoint's job, and under this requirement's own constraint an
  unsupervised session cannot edit that layer anyway.
- The GitHub Actions route. Documented as the rejected alternative with its
  cost; adopting it needs the credential decision first
  (`.agents/harness/AGENTS.md`, stop and ask for credentials).
- A cap on firings, spend, or fleet size. Declined by the requester on
  2026-08-24; the requirement's Constraints records it. Do not add one
  here — but this plan's file is the right place to note that the research
  argued for reconsidering it, so the human sees the argument without the
  plan acting on it.

## Acceptance

- `.agents/docs/unsupervised.md` exists and states, for each of the five
  mechanisms, whether it survives the session that created it. That single
  question is what separates them; a comparison that omits it is decoration.
- The operator procedure is runnable as written: create, inspect, pause,
  delete. Follow it end to end on a throwaway Routine and paste what each
  step printed.
- The document says what a firing does when the queue is empty and when it
  is not, and both answers are consistent with
  `unsupervised-edge-work`'s edge behaviour.
- The stop procedure is proved, not asserted: pause the throwaway Routine
  and show it does not fire. An operator who cannot halt the fleet has no
  veto, and the harness reserves veto to the human.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `.agents/harness/queue-context.sh:327` — the fan-out line the heartbeat
  feeds; the firing session reads exactly this output.
- `docs/plans/unsupervised-fanout.md` — the plan this one unblocks, and
  whose Goal defers the endurance claim to this file.
- `docs/product/unsupervised-mode.md` — Satisfied when, the "keeps going
  for hours" clause this plan is answerable for.
- `.github/workflows/update.yml` — the repo's existing scheduled workflow,
  and its comment on pull requests opened by a workflow getting no CI runs.
  That comment is the evidence behind rejecting the Actions route.
- `.agents/docs/graph.md`, Rules — no stored state; the Routine's schedule
  lives with the scheduler, and the queue stays the only source of truth
  about what is left to do.

## Traps

- Documenting a mechanism is not adopting it. This plan ships a file; the
  human decides whether the Routine exists.
- No new state store for fleet bookkeeping. Git holds it or it is not held.
- The hourly floor on a durable Routine is real. Say it plainly rather than
  implying a tighter loop the mechanism does not offer.
- `unsupervised-fanout` declares `needs: unsupervised-heartbeat` and is
  blocked until this file is deleted. They touch different files, so the
  edge is ordering, not conflict.

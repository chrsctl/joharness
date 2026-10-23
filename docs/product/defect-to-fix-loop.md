---
requirement: defect-to-fix-loop
priority: normal
---

## Goal

Requester, 2026-10-23, after a consumer manager (gx `ui-adapt-verify`)
blocked on a red suite on its base branch and a human had to ask: *"we only
asked 'can we fix' and found a proper solution, can we [add] a role
workflow etc to joharness that does this."* Then, asked for the optimal
solution, the requester chose prevention first and a lean recovery loop.

The incident: a consumer pull request merged under `finish: pass`
(`JOHARNESS_CHECKS=local`) with the consumer's own required check red. A
later manager could not meet its Acceptance and blocked for a human. The
human's one question set off, by hand, everything below. None of it
needed a human decision.

## Satisfied when

1. **Prevention.** Under `JOHARNESS_CHECKS=local`, `finish` runs one
   check the consumer declares and is red on it, so a consumer's required
   checks gate the merge rather than prose.
2. **Recovery.** A manager blocked by an agent-fixable defect outside its
   plan's scope (it cannot meet its own Acceptance while the defect stands)
   stops without a human. The defect becomes an issue the clerk plans
   urgent, and the item resumes on its own once the fix is retired. That
   issue and that block carry no `human-review` and notify nobody, unless
   nothing plans or fixes the defect within a bound. Requester's decision,
   2026-10-23: only BLOCKING defects skip the hold. Every other
   agent-filed defect keeps today's `human-review` hold.
3. **Escape.** A plan born from a defect asks where it entered, which
   check passed it, and routes the gate: this repo's is fixed or planned,
   canonical's becomes a finding `./joharness.sh upstream` reports.
4. Steps 1–2 are visible in `./joharness.sh` output (`finish`,
   `dispatch`) and leave their record in git. Step 3's answers live in
   the fix's pull request body; only a canonical-routed gate becomes a git
   record, as a `## Review` finding. Harness commands never call the
   GitHub API.

## Constraints

- Blocks that need a human (money, credentials, product, interface, core
  path, conflict, hardware, github, stalled, respawns) keep today's path.
- The clerk's gates (author gate, `human-review` skip, scout gate) are not
  relaxed.
- No core path edit (`./joharness.sh protocol-paths`) without a
  `human/<stem>` pull request.
- Out, by the requester's choice (2026-10-23): an automatic upstream
  reporter. `/upstream-report` stays a manual procedure.

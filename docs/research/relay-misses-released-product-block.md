---
research: relay-misses-released-product-block
urgency: normal
agent: opus
effort: medium
graduates: .agents/docs/orchestrator-reference.md
---

## Question

Does `orchestrator-reference.md` § Relay resume a manager whose block reason
is `product:` when its question was answered and released (an `answered:`
line, `human-review` removed) by another session before the orchestrator read
it?

## Echo

Relay fires on "an open question with an answer", and also on "a `defect:`
issue the blocked manager filed that the clerk has since released". A question
that someone else answers AND releases is no longer open. If the block's
`next:` is `product:`, not `defect:`, neither clause obviously matches, and
§ Resume (PARKED RESUME) covers only `defect:` blocks. If so, nothing wakes the
branch: the orchestrator lists it as "blocked on a human" every pass, while the
human has already answered and the unblocking work has merged.

## Sweep

`goal-directed`: one consumer incident, traced end to end.

## What would settle it

Yes: an orchestrator pass that relayed a `product:` block whose question was
already released. No: a pass that read such a block and did not relay it,
with the rule text it applied.

## Method

On the consumer (chrsctl/gx):

```
$ git show d5e16b60b:docs/handover/web-main-server-deployed.md | grep -E "^(status|next):"
status: blocked
next: product: #2144: how does a deployment hold one run-service credential per workspace?
$ git log -1 --format=%ci d5e16b60b
2026-11-22 11:00:18 +0000
$ git log --format="%h %ci" d5e16b60b..52ab441fd -- docs/handover/web-main-server-deployed.md
52ab441fd 2026-11-26 17:59:09 +0000      # the only later change: a hand relay a human asked for
```

The timeline on issue #2144 (title `defect: …`, filed by that manager):

- 2026-11-22T10:59Z: the manager's `decision needed:` comment, then the `human-review` label.
- 2026-11-26T06:18Z: `answered: option 1` from a human-driven session, which then removed `human-review` (the labels are now `approved` only).
- 06:57Z: the clerk's `clerk: HOLDS`, with `answered: option 1`, planning the fix.
- 08:02Z and 09:49Z: the fix merged on both backends (#2216, #2229). The #2229 comment says "not done: … (plan `web-main-server-deployed`)".

The orchestrator's pass reports 151 to 154 (about 13:20Z to 14:25Z) each list
"`web-main-server-deployed` (#2144) … blocked on a human".

## Findings

- **The block stayed for 4 days 7 hours, and 11 hours after the answer.** The workstream file was unchanged from 2026-11-22 11:00Z until a human-ordered hand relay at 2026-11-26 17:59Z (git log above).
- **Neither Relay clause matched as the orchestrator read them.**
  - The question was not open: it had an `answered:` line and no `human-review`.
  - The `defect:`-issue clause is worded on the issue ("a `defect:` issue the blocked manager filed"). The orchestrator acted as if it applied only to a `defect:` block reason, and this block's reason was `product:`. The rule does not say which of the two it means, the issue title or the block's `next:` reason.
- **§ Resume could not catch it either.** A `PARKED #<n> RESUME` row exists only for `next:` = `defect: #<n>: …`.
- **Cost:** the item never re-entered dispatch. Five plans and a parked queue were otherwise moving. The human found it by asking "why did we never continue".

## Consequence for the queue

`.agents/docs/orchestrator-reference.md` § Relay: a manager block of any
allowed reason whose question carries a later `answered:` line from an
author with write access counts as answered, whoever released it. Relay it
with that answer. Alternatively, state that the `defect:`-issue clause reads
the issue, not the block reason. Possibly also have dispatch flag a blocked
row whose cited issue has an `answered:` line newer than the block.

## Verification

Not verified from a second context yet; the commands above are reproducible
on chrsctl/gx.

## Graduates to

`.agents/docs/orchestrator-reference.md`: § Relay is where the orchestrator decides whether an answer exists.

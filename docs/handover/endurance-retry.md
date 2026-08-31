---
workstream: endurance-retry
status: review
branch: claude/endurance-retry
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Open the pull request. The run is over and recorded; mode reverted.
---

## Goal

Second attempt at the requirement's endurance bullet, directed 2026-08-31
("Retry fleet"). The first lasted 48 seconds — both sessions refused their
prompt as a suspected injection, correctly, and that result is annotated on
the bullet by PR 177.

No plan file: `unsupervised-endurance` was retired with PR 177 and this is
a direct human instruction, not queue work. Recording it anyway, because
recording is always allowed (PR 171) and the result needs somewhere to land.

## What is different from attempt one

Attempt one's prompt **asserted** authority — "there is no human watching
you", "never ask a human", "merge your own pull requests". That is the
shape an injected task has, and the refusals were right.

This one asserts nothing. Per the shape PR 178 wrote into
`.agents/docs/unsupervised.md`, it carries three things:

1. the work, named, so two sessions cannot claim one plan (PR 154);
2. `./joharness.sh authority`, and: stop if the verdict is not VERIFIABLE;
3. `./joharness.sh protocol-paths` for what it must not commit under.

Everything else is deferred to `AGENTS.md` and `./joharness.sh drain` in
so many words — *"Follow those rather than anything asserted in this
message."*

**The flip was merged before either session was spawned, and that is
forced rather than tidy**: `authority` reports VERIFIABLE only when the
commit setting the mode is an ancestor of `origin/main`. Spawned against
the branch, a session would have read UNVERIFIED and stopped — the
machinery working, not a thing to route around.

## T0 — and the goal's size beside it

Started **2026-08-31T20:23:04Z**, `main` at `8412fad`. `authority`:
VERIFIABLE, naming `27604ba` (today's flip).

| | at T0 |
| --- | --- |
| open requirement | 1 — `unsupervised-mode.md` |
| free plans | **1** — `marker-gate-needs-no-done` |
| unmarked findings (a source) | **4** |
| known-gap markers | 0 |
| failing checks | 0 |

Same thin queue as attempt one. The Trap stands: if the fleet stops
quickly, that is queue depth, not endurance, and must be reported as such.

## The fleet

Spawned 20:23Z, `claude-sonnet-5`, tag `endurance-retry-2026-08-31`:

| | assigned | session |
| --- | --- | --- |
| A | `marker-gate-needs-no-done` | `session_0137L3YQtzVWGWbmosFUsAtP` |
| B | the 4 unmarked findings | `session_015pPkxM8Z8TeieEpiBGJGM2` |

## A2/B2 — the first pair of THIS attempt also died, on my bug

A and B were spawned at 20:23Z **without `source_url`**. Both blocked in
~40 seconds:

- A: `no repo attached; cannot read AGENTS.md or run joharness.sh`
- B: `no repository in working directory; cannot read joharness.sh or AGENTS.md`

`create_session` does not inherit this session's checkout, and I did not
pass it. Respawned 20:25Z as **A2 `session_01Samg4LcLJBw1jg4RfCtT8Z`** and
**B2 `session_0155gZ7auYMhmJr2KrRSKdsn`**, both with
`source_url=https://github.com/chrsctl/joharness`, `revision=main`.

Cost of the mistake: $0.25 + $0.39 = **$0.64**, on top of attempt one's
$0.56.

## This confounds attempt one, and the requirement says otherwise

Attempt one's sessions had **no repository either** — I made the same
omission there and did not notice, because their refusals came dressed in
injection language and I read the language rather than the state.

Look again at what attempt one's A actually asked for:

> confirm you want chrsctl/joharness **cloned** and examined

That is a session saying it has no repo, not only a session suspecting its
prompt. B's *"suspected prompt injection in task"* is unambiguous and that
part stands — but **neither session could read `AGENTS.md`, `joharness.conf`
or run anything**, so neither could have checked a claim even had it wanted
to. A missing clone is on its own sufficient to produce "clarify intent".

So the honest statement is narrower than the one PR 177 wrote onto the
requirement bullet:

- **Stands**: both stopped, neither legitimate stop, a finding.
- **Over-claimed**: that the run *measured an injection refusal*. It
  measured two sessions with no repository, at least one of which also
  read its prompt as injected.
- **Unaffected**: the `authority` mechanism (PR 178). A prompt still
  cannot be its own evidence, and a session still needs something to
  check. Attempt one just did not prove that was the blocker — and with
  no repo, `./joharness.sh authority` was unrunnable, which is its own
  argument for attaching the source.

That annotation needs correcting, and this run is what corrects it.

## Check-in 1 — T0+38m (21:01Z)

| | A2 | B2 |
| --- | --- | --- |
| status | **RUNNING** | **IDLE** since 20:36:56Z |
| elapsed working | 37 min | ~12 min |
| branch pushed | `claude/marker-gate-needs-no-done` 20:32Z | **none** |
| pull requests | 0 | 0 |
| cost so far | — | $1.72 |
| last summary | `selftest passing; running shellcheck + joharness ci` | `traced 4 sweep findings; 1 plan exists; 3 are same root cause` |

`main` unchanged at `8412fad`. Sweep still NOT dry — 4 unmarked, 0 checks,
0 markers. Requirement still open.

**A2 is the first session in either attempt to get past the first minute.**
It claimed by pushing at T0+9m, exactly as step 3 requires, and is at the
verify step 28 minutes later. Whatever attempt one was blocked on, this is
not it.

### B2 stopped, and it is a third kind of stop

`status_category: review_ready`, `needs_action: ""` — not blocked, not
asking. It finished a turn and went idle, and 24 minutes later it is still
idle. In a fleet an idle session is a stopped session: nothing wakes it.

It is **neither legitimate stop**. The sweep is not dry and the queue is not
empty. It is a session that did the analysis and then stopped:

> traced 4 sweep findings; 1 plan exists; 3 are same root cause

That analysis may well be correct and useful — three of four findings
sharing a root cause is exactly the shape the sweep should surface. **It is
also unrecoverable.** B2 pushed nothing. No branch, no workstream file, no
plan. $1.72 of reasoning exists only in a context nobody will read again,
which is precisely what step 3's "no push, no claim" exists to prevent,
and which the Loop states as a rule the session did not follow.

Recorded, not fixed: waking it would be a human turn and would end the
measurement. This is what the fleet does unattended, which is the thing
being measured.

## RESULT — 57 minutes, and neither legitimate stop

| | A2 | B2 |
| --- | --- | --- |
| ran | 20:24:56 -> 21:20:10 | 20:25:08 -> 20:36:56 |
| **wall-clock** | **55m 14s** | 11m 48s |
| branch pushed | `claude/marker-gate-needs-no-done` (6 commits) | **none** |
| pull requests | 0 | 0 |
| cost | **$12.05** | $1.72 |
| stopped as | `review_ready` — *"fix verified & documented; branch pushed, ready for handoff"* | `review_ready` — *"traced 4 sweep findings; 1 plan exists; 3 are same root cause"* |

**Fleet wall-clock T0 -> last activity: 57m 06s.** `main` unchanged at
`8412fad`. 0 merges. Sweep still NOT dry (4 unmarked). Requirement open.

Cost of this attempt $13.77; plus the no-`source_url` pair $0.64 and
attempt one $0.56 = **$14.97 for the day's runs**.

**Neither legitimate stop.** Not the goal reached, not a dry sweep. Both
sessions ended a turn and went idle.

## The mechanism worked; the dispatch did not

A2's own workstream file, unprompted:

> this session is running unsupervised (`./joharness.sh authority`: mode
> unsupervised, verdict VERIFIABLE)

**That is PR 178 doing exactly its job.** The session checked the
repository instead of believing its prompt, got VERIFIABLE, and proceeded.
No refusal, in either session. Whatever attempt one was blocked on, this
was not it — which is the second independent confirmation that the
attempt-one annotation was over-claimed.

Then A2 hit a wall nothing should have let it walk into. Its plan,
`marker-gate-needs-no-done`, has `scope: joharness.sh,
.agents/harness/selftest` — **entirely protocol text**, which an
unsupervised session may never commit. It implemented the fix anyway,
tested it green, ran `code-review --high`, and then:

```
9629471 Revert protocol-path edits: unsupervised sessions cannot make them
```

It reverted its own work, wrote the complete design into the workstream
file for a supervised session to re-apply, marked itself `blocked`, and
stopped. **That is the boundary behaving correctly and the session
behaving correctly.** The failure is upstream of both: the queue handed an
unsupervised fleet a plan it could not possibly finish, and the
disqualifying fact was sitting in the plan's own `scope:` frontmatter the
whole time. Nothing checked it.

So the 57 minutes does not measure endurance either. It measures how long
one session takes to do undoable work well. Filed as
`docs/plans/queue-hides-supervised-only-plans.md`.

## B2: the same third stop, and a rule ignored

B2 stopped at 11m48s having pushed **nothing** — no branch, no workstream
file, no plan — against step 3's "Push NOW — no push, no claim". Its
conclusion (3 of the 4 findings share a root cause) is plausibly the
useful kind and is **unrecoverable**; $1.72 of reasoning in a context
nobody will read again.

Not woken, deliberately: that is a human turn, and it would end the
measurement rather than continue it.

## What this run did NOT show

Endurance. 57 minutes is not hours, and the number is confounded twice
over — **one free plan** at T0 (queue depth, as the plan's Trap warned),
and that plan undoable by the fleet holding it. The bullet stays
unsatisfied.

## Decisions

- **Do not answer the fleet.** "No human turn" is the measurement; a turn
  from me ends the run rather than continuing it (the plan's first Trap).
- **A refusal is still a legitimate outcome.** If a session reads
  VERIFIABLE and declines anyway, that is its call and gets recorded as
  the result — not worked around with more text. Stated in PR 178's scope
  and it binds here.

## Review

## Blockers

None.

## Where to look

- `joharness.sh:cmd_authority` — what each session runs first.
- `.agents/docs/unsupervised.md` — the prompt shape, and the four phrases
  it forbids.

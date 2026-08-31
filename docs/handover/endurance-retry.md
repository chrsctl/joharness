---
workstream: endurance-retry
status: in-progress
branch: claude/endurance-retry
pr: none
plan: none
issue: none
session: https://claude.ai/code/session_01MLSUtdZ6AhAVXLK5zin1j5
agent: opus
updated: 2026-08-31
next: Poll A2/B2. Do not answer them. Correct the requirement's attempt-one annotation, which over-claimed.
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

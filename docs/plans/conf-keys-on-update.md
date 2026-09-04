---
plan: conf-keys-on-update
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: .agents/scripts/conf-keys.sh, .agents/scripts/sync-to-consumer.sh, .agents/scripts/bootstrap-consumer.sh, .agents/harness/selftest/sync-to-consumer.sh, .agents/harness/selftest/bootstrap-consumer.sh, .agents/docs/consumer-repos.md
---

## Goal

A child is asked about every switch at first contact and never again. The
conf is consumer-own and the sync never touches it, so a child bootstrapped
before a setting existed carries no line for it and takes the fail-closed
default in silence — `JOHARNESS_MODE` landed this week and every repo
bootstrapped before it is in exactly that position. Requester: on update, ask
about settings the child does not have.

## Scope

- `.agents/scripts/conf-keys.sh` — ONE declaration of the keys a child runs
  under, each with its default and a one-line meaning. Sourced by both
  scripts. `.agents/scripts` is canonical-only, so this reaches every update
  without shipping anything to a consumer.
- `.agents/scripts/sync-to-consumer.sh` — a report stage naming the declared
  keys the consumer's conf lacks, and an interactive ask that adopts the ones
  answered. Report always; ask only with a terminal; write only what somebody
  answered.
- `.agents/scripts/bootstrap-consumer.sh` — read the declaration rather than
  carrying a second copy of the same list.
- Both selftest topics — cases for the report, the ask, the refusal to write
  unattended, and one that reds if the two lists ever disagree.
- `.agents/docs/consumer-repos.md` — what update now says and asks.

## Out of scope

- **Syncing the conf.** It stays consumer-own. The sync gains the ability to
  APPEND a key a human just answered for, and nothing else: no overwrite of a
  value the consumer holds, no write at all without an answer.
- **Writing anything from `update.yml`.** That runs on a cron with nobody to
  ask. It gets the report, in the pull request body it already carries, and
  the human decides from there. No flag is added to make it adopt.
- **Removing a key a consumer has and canonical does not.** Reported by the
  existing unused-file machinery's reasoning, not deleted; a consumer's own
  key is its own.
- **Re-asking about a key the consumer already has.** Update is not a second
  bootstrap; only ABSENT keys are named.
- **Changing any default, or what any key means.**

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed; the diff touches non-`*.md` files under
  `.agents/scripts/`, so step 7 requires it.
- A sync against a consumer missing a declared key names that key, its default
  and its meaning, and says the conf was not written.
- The same sync with no terminal writes nothing and still reports.
- Under a pty, answering adopts the key with the answered value; declining
  leaves the conf byte-identical.
- A consumer whose conf holds every declared key gets no report stage at all.
- One case reds if the bootstrap's seeded conf and the declaration ever name
  different key sets — the drift this plan exists to prevent.
- Each new case made to fail by injection with `./joharness.sh mutate`.
- SHIPS: nothing new. `.agents/scripts` is canonical-only; the consumer-side
  effect arrives through the sync report and `update.yml`'s existing pull
  request body.

## Where to look

- `.agents/scripts/sync-to-consumer.sh:report_unused_layers` — the shape a
  report stage takes here, and where the new one goes beside it.
- `.agents/scripts/sync-to-consumer.sh:CANONICAL_ONLY_DIRS` — proves
  `.agents/scripts` never ships, which is why one declaration reaches every
  consumer's update without being copied into any of them.
- `.agents/scripts/bootstrap-consumer.sh:interview` — the questions, and the
  seed heredoc below it that currently holds the second copy of the list.
- `.github/workflows/update.yml` — the `Sync report:` block already carried
  into the pull request body; the new stage rides it with no change there.

## Traps

- Two readers of one fact disagree. The declaration is the point of this
  plan; a key added to the seed and not to it must red a case.
- `read` under `set -euo pipefail` returns nonzero at end of input.
- A dry run must leave the consumer byte-identical, so it never asks.
- The conf is consumer-own. Appending an answered key is the whole licence;
  rewriting a value the consumer holds is not in it.

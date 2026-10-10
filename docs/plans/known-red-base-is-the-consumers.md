---
plan: known-red-base-is-the-consumers
urgency: normal
agent: haiku
effort: low
needs: none
requirement: none
scope: shared:.agents/docs/consumer-repos.md
---

## Goal

Issue #305, option 1. In a consumer with a red base branch, at least four
managers each rebuilt a baseline and re-ran the full suite to attribute
the same pre-existing failures. The harness has nowhere to put that
reading and says nothing either way about whose job it is. That silence is
what produced four baseline runs in a day. Say it once: the record is the
consumer's, and step 7 still binds.

## Scope

- `.agents/docs/consumer-repos.md` — a new section `## A red base branch`,
  placed directly before `## The sync pull request: drive it to merged`.
  Content, in caveman style (`.agents/docs/caveman.md`), four points, no more:
  1. The harness keeps no record of which tests are red on the base. `ci`
     and `finish` read git and the tree, never a check run.
  2. A consumer that wants one owns it, in its own `docs/`, never synced.
  3. Step 7's rule still binds every manager: "base green" is an
     infrastructure reading, "re-derived at every check, never inherited".
     A record cannot replace a manager's own check. At most it tells the
     manager what to expect before it checks.
  4. How such a record should be shaped is an open question (#305: "Not
     claimed: that (2) is correct"). The harness does not prescribe one.

## Out of scope

- Any harness file for the record, any reader in `ci`/`finish`, any GitHub
  read (#305 options 2 and 3).
- Any other section of `consumer-repos.md`.

## Acceptance

- `grep -c "^## A red base branch" .agents/docs/consumer-repos.md` → `1`.
- `awk '/^## A red base branch/{a=NR} /^## The sync pull request/{b=NR} END{print (a && a<b)}' .agents/docs/consumer-repos.md` → `1`.
- `./joharness.sh ci` → `ci: pass` (anchors, glossary).
- SHIPS: `.agents/docs/consumer-repos.md` reaches consumers. The consumer
  check is the same `grep` in a consumer after its next sync.

## Where to look

- `.agents/docs/consumer-repos.md:## The sync pull request: drive it to merged` — where the section goes.
- `.agents/harness/AGENTS.md` — step 5 (measured number) and step 7
  (infrastructure reading re-derived at every check).
- `.agents/docs/feedback.md` — "Trust counted numbers, never written
  numbers". The new section must not contradict it.

## Traps

- `orchestrated-only-docs` also edits `consumer-repos.md` (link fixes). Both
  mark it `shared:`. Reconcile at step 7.
- Glossary lint covers `.agents/docs/`. Run `ci` after writing.

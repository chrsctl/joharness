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
consumer's, and the harness rules bound its shape.

## Scope

- `.agents/docs/consumer-repos.md` — a new section `## A red base branch`,
  placed directly before `## The sync pull request: drive it to merged`.
  Content, in caveman style (`.agents/docs/caveman.md`), four points:
  1. The harness keeps no record of which tests are red on the base. `ci`
     and `finish` read git and the tree, never a check run.
  2. A consumer that wants one owns it, in its own `docs/`, never synced.
  3. Shape, from `.agents/harness/AGENTS.md` step 5 ("Measured number
     carries what produced it, same sentence"): base sha, command, UTC
     time, failing set. A manager whose merge base IS that sha may read
     it. Any other base: re-derive and rewrite it. That keeps step 7's
     rule: an infrastructure reading is never inherited across a base
     change.
  4. Every merge may touch it, so it is a registry: mark it `shared:` in
     every plan's `scope:` that writes it (`.agents/docs/plans/README.md`).

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
  numbers". The new section must not contradict it: the record is a
  measurement with its provenance, keyed by sha.

## Traps

- `orchestrated-only-docs` also edits `consumer-repos.md` (link fixes). Both
  mark it `shared:`. Reconcile at step 7.
- Glossary lint covers `.agents/docs/`. Run `ci` after writing.

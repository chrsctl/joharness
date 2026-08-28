---
plan: backpass-compat
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: CLAUDE.md, AGENTS.md, .backpassrc.json, .gitignore, .agents/docs/backpass.md, .agents/docs/handover/README.md
---

<!-- Same-session plan: direct human ask ("Review usage
https://github.com/kunchenguid/backpass" then "Adapt"), decomposed here,
executed on this branch. Deleted in same PR as code. -->

## Goal

Review found [backpass](https://github.com/kunchenguid/backpass) (transcript-driven,
evidence-gated AGENTS.md editor) sound but misfit: it resolves no `@` imports —
`isPointerTo` in its `src/memory.js` accepts only a file whose sole content is
`@AGENTS.md`. Our CLAUDE.md = pointer + `## Handover` section, so backpass
classifies it "separate", warns divergence every run, never optimizes it. Human
said: adapt. Shape repo so backpass runs clean on canonical and every consumer.

## Scope

- `CLAUDE.md` — pure pointer: comment + `@AGENTS.md`, nothing else. Synced
  whole to consumers, so fix propagates.
- `AGENTS.md` — `## Handover` summary moves here from CLAUDE.md, ABOVE the
  `# Part 2 — project` marker (canonical-owned region, sync splices it
  forward). Non-Claude harnesses read AGENTS.md natively and never resolve
  imports — they gain the summary.
- `.backpassrc.json` — new, repo root: `skillsDir` `.claude/skills` (backpass
  default `.agents/skills` collides with two-layer rule), explicit
  `memoryFiles`. Consumer-own file class, canonical only.
- `.gitignore` — add `.backpass/`. `backpass init` uses `.git/info/exclude`;
  tracked entry stops a session committing state from a clone that never ran
  init.
- `.agents/docs/backpass.md` — new: why CLAUDE.md stays pure, import
  blindness, transcripts local-only. Ships to consumers via `.agents/docs`.
- `.agents/docs/handover/README.md` — layer-1 paragraph ("How a session finds
  this") still says CLAUDE.md states protocol; update to match move.

## Out of scope

- Editing backpass itself, forking it, filing upstream issues. Separate work.
- Adopting backpass ideas (gap ledger, two-session rule) into
  `./joharness.sh feedback`. Own plan if wanted.
- Adding `.backpassrc.json` to sync FILES list. Per-repo choice like
  `joharness.conf`; revisit after backpass proves out on canonical.
- Archiving remote-session transcripts for backpass. Privacy + weight; not
  this plan.
- Deduplicating `## Handover` between AGENTS.md and `.agents/harness/AGENTS.md`.
  Same duplication existed before (CLAUDE.md vs harness file); moving text is
  this plan, rewriting rules is not.

## Acceptance

- `sed 's/<!--.*-->//' CLAUDE.md | grep -v '^[[:space:]]*$'` — exactly `@AGENTS.md`.
- `awk '/^# Part 2/{exit} /^## Handover/{print "ok"}' AGENTS.md` — `ok`.
- `python3 -c "import json; json.load(open('.backpassrc.json'))"` — silent.
- `./joharness.sh ci` — pass.

## Where to look

- `.agents/scripts/sync-to-consumer.sh:FILES` — CLAUDE.md synced whole, no
  marker; AGENTS.md spliced at Part 2 marker. The comment block at top is the
  contract this plan leans on.
- `.agents/docs/handover/README.md:How a session finds this` — layer 1 names
  CLAUDE.md.

## Traps

- `# Part 2 — project` marker line in AGENTS.md must survive byte-exact —
  sync splices at it; a consumer AGENTS.md without it fails sync runs.
- CLAUDE.md: any future content added there breaks pointer purity silently.
  That is what `.agents/docs/backpass.md` exists to say.
- `.agents/harness/` untouched — this plan lives in root files + docs.

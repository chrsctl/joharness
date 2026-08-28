# backpass

[backpass](https://github.com/kunchenguid/backpass) = transcript-driven,
evidence-gated editor for AGENTS.md: reads past agent sessions from local
harness stores, proposes a capped batch of evidence-backed edits per run (5
near budget; up to 20 when shrinking an over-budget file — cap is adaptive),
human accepts or rejects each (`backpass apply` = only writing command). Adopted for
local use 2026-08-28; this file = repo shape it depends on. Break the shape,
backpass degrades silently — nothing else in `ci` checks it. Behavior facts
here verified against backpass 0.1.8 source — newer backpass, re-check there,
not here.

## Repo shape

- `CLAUDE.md` = pure pointer: `@AGENTS.md` plus HTML comments, NOTHING else.
  backpass (`src/memory.js:isPointerTo`) strips comments, then demands exactly
  that one line. One added content line = file classified "separate": warned
  as divergence hazard every run, never optimized. Instruction text goes in
  root `AGENTS.md`, never CLAUDE.md.
- backpass resolves NO `@` imports. It audits root `AGENTS.md` ONLY —
  `.agents/harness/AGENTS.md`, environment layers, docs invisible to it. Rule backpass
  should see and optimize = rule in root AGENTS.md (Part 1 synced to
  consumers, Part 2 per-repo). Revisit if upstream learns import resolution.
- Consumer repo: accept backpass edits into Part 2 ONLY. Part 1 (above
  `# Part 2 — project` marker) is canonical-owned — a consumer-side edit
  there makes AGENTS.md AHEAD on every future sync, harness updates stop
  flowing. Part 1 fixes land in joharness first.
- `.backpassrc.json` (repo root, per-repo like `joharness.conf`, NOT synced —
  consumer adopting backpass creates its own): pins `skillsDir` to
  `.claude/skills` — repo skills live there and sync to consumers; backpass
  default `.agents/skills` names a tree this repo does not have, and skills
  written there would never sync.
- `.backpass/` = state dir, gitignored. Never commit it.

## Where it runs

Local machine with local CLI sessions only. Adapters read on-disk stores
(`~/.claude/projects/...` etc.). Remote-container session transcripts never
land there and the container is ephemeral — corpus in a web session = empty.
Do not run backpass from a web session; nothing to analyze.

## Applying edits

Accepted edits are ordinary AGENTS.md changes: caveman style
([`caveman.md`](caveman.md)), counted numbers only, commit like any edit.
Extraction targets (`SKILL.md`) land in `.claude/skills/` and sync to
consumers — review them as harness changes.

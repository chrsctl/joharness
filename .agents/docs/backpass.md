# backpass

[backpass](https://github.com/kunchenguid/backpass) = transcript-driven,
evidence-gated editor for AGENTS.md: reads past agent sessions from local
harness stores, proposes at most five evidence-backed edits per run, human
accepts or rejects each (`backpass apply` = only writing command). Adopted for
local use 2026-08-28; this file = repo shape it depends on. Break the shape,
backpass degrades silently — nothing else in `ci` checks it.

## Repo shape

- `CLAUDE.md` = pure pointer: `@AGENTS.md` plus HTML comments, NOTHING else.
  backpass (`src/memory.js:isPointerTo`) strips comments, then demands exactly
  that one line. One added content line = file classified "separate": warned
  as divergence hazard every run, never optimized. Instruction text goes in
  root `AGENTS.md`, never CLAUDE.md.
- backpass resolves NO `@` imports. It audits root `AGENTS.md` ONLY —
  `.agents/harness/AGENTS.md`, env layers, docs invisible to it. Rule backpass
  should see and optimize = rule in root AGENTS.md (Part 1 synced to
  consumers, Part 2 per-repo). Revisit if upstream learns import resolution.
- `.backpassrc.json` (repo root, per-repo like `joharness.conf`, not synced):
  pins `skillsDir` to `.claude/skills` — repo skills live there and sync to
  consumers; backpass default `.agents/skills` names a tree this repo does
  not have.
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

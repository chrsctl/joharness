---
plan: flatten-agents-readmes
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
serves: all
issue: none
scope: .agents/docs, .agents/harness, .agents/scripts, .agents/env, .agents/NOTICE, .claude, joharness.sh, CLAUDE.md
---

## Goal

User ask: a file named `README.md` reads as written for humans, yet the four
under `.agents/docs/` are protocol specs agents follow. Rename them to flat
`.agents/docs/<topic>.md`, beside `glossary.md` and `graph.md`. Delete
`.agents/harness/README.md`, a path table that duplicates `consumer-repos.md`
and the tree; keep its ownership prose in `consumer-repos.md`, "What syncs".

## Scope

- `git mv .agents/docs/{handover,plans,product,research}/README.md .agents/docs/{handover,plans,product,research}.md`;
  fix each moved file's relative links.
- `git rm .agents/harness/README.md`; its harness-owned vs consumer-own
  prose moves into `.agents/docs/consumer-repos.md`, "What syncs".
- Every reference to the old paths in `joharness.sh`, `.agents/`,
  `.claude/`, `CLAUDE.md`.
- The env READMEs (`.agents/env/README.md`, `docker/`, `k8s/`) stay: human
  setup guides and the layer contract.

## Assumptions

- A1: no script reads `.agents/docs/<topic>/README.md` by path as data, only
  in messages and comments — evidence: `git grep 'docs/[a-z]*/README'
  joharness.sh .agents/harness/*.sh` — confidence: medium
- A2: the `*/README.md` exclusions in scripts are for the repo-root `docs/`
  work dirs, not `.agents/docs/` — evidence: `joharness.sh:lint_stem`
  neighbours, `handover-context.sh` line on TEMPLATE/README — confidence: high

## Out of scope

- Comments in core paths (`joharness.conf`, `.github/workflows/update.yml`)
  naming `.agents/docs/product/README.md`: a `human/` pull request, a human
  merges it.
- The `docs/*/README.md` exclusions for repo-root work dirs: consumers may
  hold such files.
- Deleting the old files from consumers: removals do not travel at sync.

## Acceptance

- `git grep -nE '\.agents/docs/(handover|plans|product|research)/README|harness/README' -- ':!joharness.conf' ':!.github'` — no output.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 0 failed.

## Where to look

- `.agents/scripts/sync-to-consumer.sh:FILES` — what ships to consumers.
- `.agents/docs/consumer-repos.md:What syncs` — ownership pointer.

## Traps

- Never edit a core path outside a `human/<stem>` branch.
- Never skip or disable a test to get green.

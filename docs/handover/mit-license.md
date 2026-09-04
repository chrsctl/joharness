---
workstream: mit-license
status: done
branch: claude/mit-license-ijf0vy
pr: none
plan: mit-license
issue: none
session: https://claude.ai/code/session_014oTKfpgfCaRPHB8pThK2uV
agent: haiku
updated: 2026-09-04
next: Retire plan and this file in the last commit before the pull request opens, then open it
---

## Goal

Human asked, verbatim: "at mit license". Repo carries no license file. Add MIT
so the harness a consumer copies has an explicit grant.

## Decisions

- Copyright line `Christian Westhoff and joharness contributors`, not `chrsctl`
  and not `Anthropic`. Human owns the repo; `git log --format='%an' | sort |
  uniq -c` (2026-09-04, full history) counts 737 Claude, 195 Westhoff, 37
  Daniel Naujocks, so a sole-holder line contradicts the tree it ships with.
- Year 2026 only. Single-year form is what a first license file takes; a range
  would claim publication years the history does not have.
- No SPDX headers in harness files. They get copied into consumer repos whose
  own license governs — a header would travel with the copy and assert the
  wrong terms there.

## Rejected

- README badge (shields.io). Adds a network fetch to a README that has none and
  says nothing the `## License` line does not.
- Adding `LICENSE` to `sync-to-consumer.sh`'s `FILES`. It would overwrite a
  consumer's own license file on every sync — the opposite of what the missing
  notice needs.
- Adding `LICENSE` to `bootstrap-consumer.sh`'s purge list. Right shape, wrong
  branch: it changes a shipped script and needs its own plan and its own
  selftest run.

## Review

- r1: `README.md` claimed the consumer's own license governs its tree, while
  `sync-to-consumer.sh` ships `joharness.sh`, `.agents/harness/`,
  `.agents/docs/` and `.claude/` with no notice and no per-file header — the
  condition `LICENSE` line 11 imposes. (fixed: README now states the gap
  instead of implying it is handled; carrying a notice to consumers needs its
  own plan, see plan "Out of scope")
- r1: `LICENSE` named one holder. Contributor counts above contradict it.
  (fixed: `and joharness contributors`)
- r1: `bootstrap-consumer.sh` purges joharness's conf marker and docs from a
  whole clone but would leave a root `LICENSE`, so the clone ships this repo's
  copyright over the consumer's product code. It already warns that
  `README.md` is still joharness's and does not warn for `LICENSE`.
  (wontfix here — changes a shipped script; recorded in the plan's Out of
  scope for a follow-up plan)
- r1: plan's `SHIPS:` acceptance bullet was false both ways — `ci` prints
  `mit-license: canonical-only`, and no `ci` stage lints root-README links.
  (fixed: bullet now records the canonical-only verdict as correct)
- r1: plan's out-of-scope line claimed `.agents/docs/caveman.md` already names
  its upstream MIT terms; it names the upstream and the word MIT, no holder and
  no notice text. (fixed: reworded, and flagged as the human's judgement)
- r1: (verifier) independent haiku reader over the same diff returned a clean
  pass — MIT text byte-exact, frontmatter and anchors valid, acceptance
  commands pass. It did not reach any finding above; recorded as the clean pass
  it was, not as agreement. (no change needed)

## Blockers

None.

## Where to look

- `LICENSE` — the grant.
- `README.md` — `## License`, last section.

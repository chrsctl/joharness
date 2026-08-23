---
requirement: handover-stop-guard
priority: normal
---

<!-- Proposed by extensions-research session 2026-08-23. Merge = ratify. -->

## Goal

Finishing ritual (update workstream file, commit with code, push) is
honor-system, asked exactly when session least attentive — protocol's own
words: sessions rarely get to say goodbye. Claude Code `Stop` hook can
read git facts at turn end and print a reminder into context: tree dirty;
commits ahead of origin unpushed; code changed since merge-base but no
workstream file touched. Facts only — same doctrine as session-start hook,
which already proved the mechanism.

## Satisfied when

- Stop hook prints reminder when tree dirty, or branch ahead and
  unpushed, or branch changes code without a `docs/handover/` file.
- Silent when clean and pushed. Never blocks, never fails a session.
- Wired in `.claude/settings.json` (synced — consumers inherit).
- Selftest covers fire and silent cases, same fixture style as
  handover-context cases.

## Constraints

- Git facts only. No liveness inference, no field parsing beyond what
  session-start already does.

---
requirement: plan-authoring-command
priority: normal
---

<!-- Proposed by extensions-research session 2026-08-23. Merge = ratify. -->

## Goal

`/handover` made the finishing ritual one word; decomposition has none.
Plans written freehand: zero of four current queue plans declare `scope:`,
so wave partitioning (parallel proven, not assumed) never fires;
frontmatter vocabulary unchecked at write time. `/plan` command guides a
decomposing session through the template: scope AND out-of-scope explicit,
acceptance = runnable commands with expected output, traps from Part 2,
agent tier by selection rules, `scope:` declared or explicit `none` — on
the record either way.

## Satisfied when

- `.claude/commands/plan.md` exists, mirrors `/handover` shape (inline, no
  subagent, numbered steps).
- Plans it produces pass graph-edge-lint vocabulary if that requirement
  lands; command stands alone if not.
- Consumers inherit (`.claude/commands` already syncs).

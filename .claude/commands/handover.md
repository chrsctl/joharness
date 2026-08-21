---
description: Write or update this branch's handover file so the next session can pick up
---

Update handover file for this session's work. Protocol:
`docs/handover/README.md`. Inline — no subagent.

1. Find this branch's file under `docs/handover/`. None + real work done?
   Create from `docs/handover/TEMPLATE.md`. Name = workstream, not branch.
2. Refresh frontmatter: `status`, `updated` (today), `pr` if exists, `session`
   (this session's claude.ai/code URL if known), `next` = ONE concrete action,
   phrased as instruction to next session.
3. Add learnings to **Decisions**, **Rejected**, **Blockers**. Rejected =
   highest value: what tried, what exactly broke.
4. Session proved something wrong? Fix it. Dead entries: delete, not annotate.
5. Leave out what git/GitHub already knows — diffs, counts, CI state. Claim
   goes stale after next push? Does not belong.
6. Commit WITH the code it describes. Tree clean? Commit file alone.
7. Push. Unpushed = invisible.

Work finished? Six-month-worthy bits go to the right layer's `AGENTS.md`
(needed every session) or `docs/` (background). Delete workstream file same
commit.

$ARGUMENTS

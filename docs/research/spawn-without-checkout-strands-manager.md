---
research: spawn-without-checkout-strands-manager
urgency: normal
agent: sonnet
effort: medium
graduates: .claude/commands/orchestrate.md
---

## Question

Does `orchestrate.md` state what a manager spawn without `source_url` costs, so that an orchestrator which omits it learns that from the page and not from a stranded session?

## Echo

A consumer orchestrator (chrsctl/gx) spawned managers with `create_session` and no `source_url`. One manager never started. The page names `source_url` in one clause of the Manager spawn bullet and says nothing about what happens without it. What rests on the answer: whether that clause needs a consequence beside it, or the miss was the orchestrator's alone and the page is fine.

## Sweep

goal-directed: only what is needed to say whether the page's wording misled, not whether the spawn tooling is sound.

## What would settle it

Either the transcripts show the stranded manager could have recovered from inside its session with what the spawn prompt gave it (the page is fine; the miss was the orchestrator's), or they show the prompt text the page prescribes leaves a manager with no way to recover (the page needs a consequence beside the clause).

## Method

Consumer repo chrsctl/gx, orchestrator session_0132SwBkvDE4dAUiXcUdhaJF, 2026-10-14. All via the Claude Code Remote MCP:

- `get_session` on session_019d3QvJT7wqPNSTtdQgXbyU, session_01Pzr75MF6FNa2oBj1JWuJGn, session_01249wSrZJKFnbR38MtiqjPz, session_01JLic6GPghTzmNRuAAPpJtu: compare `tags` and `session_context.sources`.
- `list_events` on the first two: read what each did in its first turn.
- `grep -n source_url .claude/commands/orchestrate.md` in gx.

## Findings

- **The page does say `source_url` (gx `orchestrate.md:263`, Manager bullet: "`create_session` with `source_url` = `git remote get-url origin`"); the orchestrator omitted it on the 5 manager spawns it made from 16:51Z to 18:19Z (canvas-builder-design, web-structure-and-routing, realestate-audio-and-video-templates twice, realestate-image-templates).** `get_session` shows each omitted spawn tagged `config:no-git-repo` and, at creation, no `sources`; the respawn made with `source_url` shows `sources:[{git_repository:{url:https://github.com/chrsctl/gx}}]` and no such tag. This is the orchestrator's miss, not a wrong rule.
- **Without a checkout the manager cannot recover on the page's terms.** session_01Pzr75M… ran `ls` in an empty `/home/user`, found no `joharness.sh`, and stopped: `/manage` was not installed (repo skills load only after a repo is attached) and the task "came only via automated notice". It declined two orchestrator messages telling it to `add_repo`. 0 commits, no claim, 18:05Z to 18:28Z.
- **Self-attaching is not reliable.** session_019d3QvJ… did `add_repo` (push) then `git clone`, which the auto-mode classifier denied as "[Permission Grant]"; its prompt had said the spawn was legitimate and that did not count. session_01JLic6G…, same shape of prompt plus an explicit `add_repo` instruction, attached and cloned and started work (claim visible 18:29Z). Same orchestrator, same environment, two outcomes.
- **Cost here:** 2 of the 5 sessions never started, both on one item (realestate-audio-and-video-templates): about 40 minutes (17:50Z to 18:29Z) with that item unclaimed, one of the two `respawns` the item is allowed spent, and one human turn spent on diagnosis. A third (canvas-builder-design) declined its first prompt as unverified and started only after an orchestrator message; the fourth (web-structure-and-routing) started unaided.

## Consequence for the queue

`.claude/commands/orchestrate.md`, Manager spawn bullet: add the consequence beside the clause ("without it the session starts in an empty directory with no `/manage`; a manager cannot be relied on to attach the repo itself"). The rule is right; the sentence does not say why it is a rule. A reviewer should weigh whether that is worth a line or whether the orchestrator simply must read its own page. This is a wording finding, not a defect in the spawn tooling.

## Verification

Not yet verified from a second context.

## Graduates to

`.claude/commands/orchestrate.md`: the spawn bullet is where an orchestrator looks when it spawns, so the consequence belongs there and not in a rule line elsewhere.

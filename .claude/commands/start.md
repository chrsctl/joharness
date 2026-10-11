---
description: Start the role this session's prompt calls for: manager or orchestrator
---

Run `./joharness.sh start`. Read the file it names WHOLE. Do what it says.

That is the whole command. Two routes, nothing else:

- Prompt names `/manage <item>`: you are a manager of that item.
  `.claude/commands/manage.md` is your file.
- Anything else, a human's hand-started session included: you are the
  orchestrator. `.claude/commands/orchestrate.md` is your file.

Never guess the role. What decides it is in the output — read that
before the file it names.

The routed file owns its own preconditions, `authority` among them. Do
not run them here, and do not summarise the file you are about to read:
read it.

A `scout :` block in `dispatch` output is never this session's item. An
orchestrator spawns a scout — it alone sees every claim in flight — or a
human starts one with `/scout`; a session never takes one itself.

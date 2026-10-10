---
workstream: role-command-trim
status: in-progress
branch: claude/role-command-trim
pr: none
plan: role-command-trim
issue: none
session: https://claude.ai/code/session_016g6mN8LJQwpLQLRc1Rmond
agent: opus
updated: 2026-10-10
next: Write the ledger in ## Review, run ci + verify, verifier, retire, PR
---

## Goal

Requester, 2026-10-09: "Is there anything to optimize also regarding the
existing harness files" — move why-text and incident history out of the
role command files into `.agents/docs/orchestrated.md`, keep every
instruction, and make `./joharness.sh context` count the role files.

## Decisions

- Baseline at claim (`wc -w`, 2026-10-10, origin/main a243fb04):
  orchestrate.md 10,080; manage.md 2,347; orchestrated.md 12,677.
- Moves done by script from exact strings, each recorded with its section
  and position; the destination section in `orchestrated.md` is generated
  from the same record, so the ledger and the moved text cannot disagree.
- Destination: two new sections at the end of `.agents/docs/orchestrated.md`,
  "Orchestrator: why, by step" and "Manager: why, by step", one `###` per
  source section. The file syncs, so no fact is behind a pointer a consumer
  lacks.
- Every selftest-pinned sentence stays (`selftest/orchestrated.sh` closing
  report block).

## Rejected

None yet.

## Review

### Ledger: every block moved out of the role files

Numbered, not bulleted: these are moves, not findings. Each block was cut by
exact string (`move_orch.py`, `move_orch2.py`, `move_mgr.py`, session
scratchpad) and the destination text generated from the same record, so a
line here and its paragraph in `orchestrated.md` name the same position.
Three referent fixes in text that STAYED, no rule changed: "this row's
second clause" -> "The LOOP row's second clause" and "the field" ->
"`updated_at`" (the example they pointed at moved), and "so a stem" ->
"A stem" (its sentence's first half moved).

1. `orchestrate.md` Tools, Tools, Claude Code Remote send_message paragraph — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Tools
2. `orchestrate.md` Tools, OPTIONAL table, `archive_session` row — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Tools
3. `orchestrate.md` Tools, OPTIONAL table, `status_bucket` row, after "Never respawn on one observation to make up for the missing field" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Tools
4. `orchestrate.md` Tools, OPTIONAL table, `set_session_title` row — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Tools
5. `orchestrate.md` 0. Preconditions, every start, step 2, after "Never replace it" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 0. Preconditions, every start
6. `orchestrate.md` 0. Preconditions, every start, step 2, after the `set_session_title` sentence — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 0. Preconditions, every start
7. `orchestrate.md` 0. Preconditions, every start, step 2, after "`respawns=<RESPAWN_LIMIT>`, on purpose" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 0. Preconditions, every start
8. `orchestrate.md` 0. Preconditions, every start, step 2, last sentences — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 0. Preconditions, every start
9. `orchestrate.md` 1. Read, first paragraph, after "Those are managers you spawned that have not claimed" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 1. Read
10. `orchestrate.md` 2. Health pass, "That URL names a WRITER, not a worker" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
11. `orchestrate.md` 2. Health pass, "And every stem your ledger names that dispatch does NOT list in flight" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
12. `orchestrate.md` 2. Health pass, same paragraph, after "or it ran and stopped without claiming" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
13. `orchestrate.md` 2. Health pass, GONE definition — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
14. `orchestrate.md` 2. Health pass, field table, `status_detail`, `updated_at` row, after "`updated_at` decides nothing ALONE, at any interval" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
15. `orchestrate.md` 2. Health pass, `context_usage.used_tokens` paragraph (the two "is NOT one" sentences stay) — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
16. `orchestrate.md` 2. Health pass, same paragraph, after "`external_metadata.current_branches` is not one either" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
17. `orchestrate.md` 2. Health pass, health table, leftovers row, after "NEVER respawn" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
18. `orchestrate.md` 2. Health pass, worked readings after the health table (IDLE alive, IDLE dead, LOOP dead and its two cautions) — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
19. `orchestrate.md` 2. Health pass, edge rows paragraph, after "holds nothing, and is only reported" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
20. `orchestrate.md` 2. Health pass, the two optional-tool sequences, after "One rule for both" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
21. `orchestrate.md` 2. Health pass, RESPAWN paragraph, last sentence — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
22. `orchestrate.md` 2. Health pass, REPORT, after "the ONE thing this role does after a manager is done" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
23. `orchestrate.md` 2. Health pass, REPORT step 3, after "whichever way it went" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
24. `orchestrate.md` 2. Health pass, reporter slot paragraph, after "A reporter holds no manager slot" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
25. `orchestrate.md` 2. Health pass, after the respawn-limit hand-off — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
26. `orchestrate.md` 2. Health pass, Explain a condition, never end one — the off case — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
27. `orchestrate.md` 3. Spawn, bullet "An item your ledger already names is spawned ONLY when THIS pass's health pass said to" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
28. `orchestrate.md` 3. Spawn, janitor bullet, after "is ORTHOGONAL to the verdict" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
29. `orchestrate.md` 3. Spawn, scout bullet, after "it is NOT orthogonal to the verdict" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
30. `orchestrate.md` 3. Spawn, scout bullet, after "The ledger key guards THIS run only" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
31. `orchestrate.md` 3. Spawn, scout bullet, after "(`.claude/commands/scout.md`, Claim)" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
32. `orchestrate.md` 3. Spawn, surveyor bullet, after "which earns ONE more (ledger the new key)" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
33. `orchestrate.md` 3. Spawn, `create_session` bullet, `source_url` — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
34. `orchestrate.md` 3. Spawn, merge line, after "The gate here is TOOL PRESENCE" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
35. `orchestrate.md` 3. Spawn, merge line, after "read your own session id with `get_session` called with no `session_id`" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
36. `orchestrate.md` 3. Spawn, merge line, after "the name `ListAgents` gives its caller" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
37. `orchestrate.md` 3. Spawn, merge line, after the quoted line to the manager — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
38. `orchestrate.md` 3. Spawn, merge line, after "the next scheduled pass finds the merge" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
39. `orchestrate.md` 4. Schedule the next pass, opening paragraph — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 4. Schedule the next pass
40. `orchestrate.md` 4. Schedule the next pass, ONE LEAD PER LINE, end of the forge paragraph — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 4. Schedule the next pass
41. `orchestrate.md` 4. Schedule the next pass, stem check, last sentence — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 4. Schedule the next pass
42. `orchestrate.md` 4. Schedule the next pass, lead bound, last sentence — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 4. Schedule the next pass
43. `orchestrate.md` 4. Schedule the next pass, `seen=` paragraph, last sentence — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 4. Schedule the next pass
44. `orchestrate.md` 4. Schedule the next pass, `same` paragraph, after "never `same`'s" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 4. Schedule the next pass
45. `orchestrate.md` Report, every pass, leads paragraph, after "what a merged manager learned about an item it did not own" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Report, every pass
46. `orchestrate.md` Report, every pass, analyst line — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Report, every pass
47. `orchestrate.md` Report, every pass, relay paragraph, after the list of health-pass actions — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Report, every pass
48. `orchestrate.md` Report, every pass, relay paragraph, last sentences — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Report, every pass
49. `orchestrate.md` Never, janitor bullet, after "One per run" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Never
50. `orchestrate.md` Never, curator bullet, after "One per run" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Never
51. `orchestrate.md` Never, last bullet, the measured run — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Never
52. `orchestrate.md` Preamble, What you read, after "Open no plan, requirement, research file or design doc" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / Preamble
53. `orchestrate.md` 0. Preconditions, every start, step 1, after "stop, say so" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 0. Preconditions, every start
54. `orchestrate.md` 2. Health pass, after the field table, "Those two are read TOGETHER or not at all" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
55. `orchestrate.md` 2. Health pass, health table, crash first-look row, after "CRASHED. NO nudge" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
56. `orchestrate.md` 2. Health pass, health table, ran-and-stopped row, after "It RAN and stopped without claiming." — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
57. `orchestrate.md` 2. Health pass, health table, merged row, after "read this row for that stem FIRST" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
58. `orchestrate.md` 2. Health pass, health table, `CEILING?` row, after "never instead of it" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
59. `orchestrate.md` 2. Health pass, `suspect a stopped fleet` paragraph, after "decides nothing" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
60. `orchestrate.md` 2. Health pass, never-born-and-FAILED paragraph, after "takes the crash rows above instead" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
61. `orchestrate.md` 2. Health pass, no-`interrupt_session` bullet, after "you cannot stop it, so you must not replace it" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
62. `orchestrate.md` 2. Health pass, LOOP intro, after "then fix once" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 2. Health pass
63. `orchestrate.md` 3. Spawn, janitor bullet, after "It writes to branches it does not own" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
64. `orchestrate.md` 3. Spawn, surveyor bullet, after "also covers any later key whose holders are all in K" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
65. `orchestrate.md` 3. Spawn, merge line, after "`<address>` the id or name it takes" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
66. `orchestrate.md` 3. Spawn, merge line, last sentence — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
67. `orchestrate.md` 3. Spawn, ledger-every-spawn paragraph, after "as `<stem>@new`" — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 3. Spawn
68. `orchestrate.md` 4. Schedule the next pass, `<head|new>` paragraph, last sentence — moved to `.agents/docs/orchestrated.md`:Orchestrator: why, by step / 4. Schedule the next pass
69. `manage.md` R. Surveyor, first bullet, after "becomes `shared:<path>`" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / R. Surveyor
70. `manage.md` R. Surveyor, second bullet, after "becomes that file" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / R. Surveyor
71. `manage.md` R. Surveyor, third bullet, after "stays exactly as it is" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / R. Surveyor
72. `manage.md` R. Surveyor, "Mark BOTH sides of a collision" paragraph — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / R. Surveyor
73. `manage.md` R. Surveyor, same paragraph, after "never touch anything below the frontmatter" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / R. Surveyor
74. `manage.md` R. Surveyor, last paragraph, last sentence — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / R. Surveyor
75. `manage.md` 4. Finish, first paragraph, after "\"merged <stem>\" to it" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
76. `manage.md` 4. Finish, follow-up plan paragraph, last sentence — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
77. `manage.md` 4. Finish, GitHub lost, "After it" bullet, after "exit" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
78. `manage.md` 4. Finish, LEAD paragraph, after "**And one thing more, when you have one: a LEAD.**" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
79. `manage.md` 4. Finish, stem paragraph, before "a stem you cannot name" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
80. `manage.md` 4. Finish, stem paragraph, after "goes in your pull request body instead" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
81. `manage.md` 4. Finish, after "Never send your own findings" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
82. `manage.md` 4. Finish, after "One lead, not a list" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
83. `manage.md` 4. Finish, refusal paragraph, after "do not retry on the other transport" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
84. `manage.md` 4. Finish, rescope conflict, after "`git rm` the workstream file)" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish
85. `manage.md` 4. Finish, upstream-feedback paragraph, after "the output that produced it" — moved to `.agents/docs/orchestrated.md`:Manager: why, by step / 4. Finish

### Sizes

Counted 2026-10-10 with `wc -w`, merge base a243fb04 vs this branch:
orchestrate.md 10,080 -> 7,106; manage.md 2,347 -> 1,921;
`./joharness.sh context` prints -2974 and -426 words vs merge base.

### Why orchestrate.md stays above 6,000

Per remaining block, what it is: an imperative the role executes, a table it
fills, or a field / number it compares against. Nothing below is a why the
role could drop and still act the same.

* Preamble + Tools: which tools, which server, the two transports and their
  addresses; REQUIRED vs OPTIONAL and, per absent tool, what the role does
  instead. Every cell is an action.
* §0: five preconditions, each a check with its exit; the `@new` rebuild
  procedure; ledger contents.
* §1: the dispatch invocation, the pending-spawn count, and the two
  slot-short rules.
* §2: the field table (pinned, `joharness.sh` cites it) and the health
  table — 26 rows, each a condition and its action; the GONE definition;
  the pointer + two rules kept from the worked readings; KILL, LOOP,
  RESPAWN, REPORT and the respawn-limit hand-off, each a numbered procedure
  with the exact text the role writes; the analyst gate.
* §3: one bullet per spawn kind — title, model, prompt, ledger key and the
  ONLY-when gate; the manager prompt block and the merge-line construction.
* §4: the `send_later` message format, the lead rules (sentences pinned by
  `selftest/orchestrated.sh`), the strip-and-cut rule, the loss-cost list
  (how to rebuild each field after a compaction, merged by plan
  `ledger-losses-named` — reconciled, not undone), the `same` rule and the
  exit verdicts.
* Report + Never: what to print, and the prohibitions.

Getting under 6,000 would mean dropping or merging imperatives — out of
scope ("Moving, not editing").

### Findings

## Blockers

None.

## Where to look

- `joharness.sh:ctx_report` — role-file block.

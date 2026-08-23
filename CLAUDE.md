@AGENTS.md

## Handover

One workstream file per work, `docs/handover/`, on work branch. Protocol:
[`.agents/docs/handover/README.md`](.agents/docs/handover/README.md).

- Hook prints state at session start. Names file for this branch? Read whole
  file before touching code.
- Update file in SAME commit as change. Before ending unfinished turn.
- Push as soon as work has name. Unpushed = invisible to other sessions.
- Push time not liveness. Overlap flagged? `/who`. Only `RUNNING` = taken.
- `/handover` writes file. `/who` shows live sessions.

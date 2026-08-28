# AGENTS.md

@.agents/harness/AGENTS.md

Environment rules are NOT in this file. `joharness.sh session-start` injects
a read-first pointer to them — or, `JOHARNESS_ENV_MD=eager`, the rules
whole — from the layer named in `joharness.conf`. See
[`.agents/env/README.md`](.agents/env/README.md); switch with
`./joharness.sh env <name>`.

## Handover

One workstream file per work, `docs/handover/`, on work branch. Protocol:
[`.agents/docs/handover/README.md`](.agents/docs/handover/README.md).

- Hook prints state at session start. Names file for this branch? Read whole
  file before touching code.
- Update file in SAME commit as change. Before ending unfinished turn.
- Push as soon as work has name. Unpushed = invisible to other sessions.
- Push time not liveness. Overlap flagged? `/who`. Only `RUNNING` = taken.
- `/handover` writes file. `/who` shows live sessions.

---

# Part 2 — project

This repo IS the harness. Both layers live under `.agents/` — one dotted
root any tool can detect: [`.agents/harness/`](.agents/harness/README.md)
always runs, one [`.agents/env/<name>/`](.agents/env/README.md) is selected.
Cross-layer coupling is the bug this structure exists to prevent —
`.agents/harness/` names no specific environment. `none` is not one: it is
the harness's own word for the absence of one. Exactly one carve-out, spelled
once in the selftest that enforces the rule (`LAYER_CARVE_OUT_*`). A second
one is a red run, not a judgement call.

Verify (all green or not done):

```bash
./joharness.sh ci        # ci: pass — same checks .github/workflows/ci.yml runs
./joharness.sh verify    # 0 failed — pass count is the layer's. This repo's layer
                         # needs the sandbox, so CI cannot run it here
```

Run `ci` before opening a pull request. GitHub also runs `verify` for any
layer declaring itself CI-runnable (`.agents/env/README.md`), which `ci` does
not — so run that layer's verify too before believing a green `ci` predicts a
green PR. Red PR after both green is a bug in the split, not bad luck.
`verify` provisions the selected environment first, so a cold container is
fine. Trust counted numbers, never written numbers — a pass total written
here would be true for exactly one layer.

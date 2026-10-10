# AGENTS.md

@.agents/harness/AGENTS.md

Environment rules: `joharness.sh session-start` injects a pointer to the layer
named in `joharness.conf` (`JOHARNESS_ENV_MD=eager`: the rules whole). See
[`.agents/env/README.md`](.agents/env/README.md); switch with
`./joharness.sh env <name>`.

---

# Part 2 — project

This repo IS the harness. `.agents/harness/` always runs; one
`.agents/env/<name>/` is selected. `.agents/harness/` names no specific
environment (`none` = absence of one). One carve-out, spelled in the selftest
(`LAYER_CARVE_OUT_*`); a second one is a red run.

Verify (all green or not done):

```bash
./joharness.sh ci        # ci: pass
./joharness.sh verify    # 0 failed — read the count the layer prints
```

This repo's layer is CI-runnable, so GitHub also runs `verify`; read the run
to see which layers it verified and which it skipped.

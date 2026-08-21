# AGENTS.md

@harness/AGENTS.md

Environment rules are NOT in this file. `joharness.sh session-start` injects
a read-first pointer to them — or, `JOHARNESS_ENV_MD=eager`, the rules
whole — from the layer named in `joharness.conf`. See
[`env/README.md`](env/README.md); switch with `./joharness.sh env <name>`.

---

# Part 2 — project

This repo IS the harness. Two layers, kept apart on purpose:
[`harness/`](harness/README.md) always runs, one [`env/<name>/`](env/README.md)
is selected. Cross-layer coupling is the bug this structure exists to prevent —
`harness/` must never name a specific environment.

Verify (all green or not done):

```bash
./joharness.sh ci        # ci: pass — same checks .github/workflows/ci.yml runs
./joharness.sh verify    # 7 passed, 0 failed — needs the sandbox, so CI cannot
```

Run `ci` before opening a pull request; it is the whole of what GitHub checks,
so a red PR after a green run here is a bug in the split, not bad luck.
`verify` provisions the selected environment first, so a cold container is
fine. Trust counted numbers, never written numbers — including the one above.

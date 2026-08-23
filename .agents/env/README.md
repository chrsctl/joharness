# Environment layers

One directory per environment. A repo runs at most one, named in
`joharness.conf` (`JOHARNESS_ENV`). `none` means the harness runs alone.

```bash
./joharness.sh env          # what is selected, what else exists
./joharness.sh env k8s      # select
./joharness.sh setup        # provision it now
./joharness.sh verify       # provision, then run its smoke test
```

## Contract

Every file optional. Layer with no `setup.sh` provisions nothing — that is all
`none` is, no special case in the entrypoint.

| Path | Used for |
| --- | --- |
| `.agents/env/<name>/setup.sh` | Provision. Idempotent, safe to repeat. Executable. |
| `.agents/env/<name>/AGENTS.md` | Rules for the layer. Session start points at it (default) or injects it whole — see md is lazy too. |
| `.agents/env/<name>/smoke-test.sh` | `verify`. Exit non-zero on any failure. |
| `.agents/env/<name>/README.md` | What it provides, what it costs, why. |

Layer is self-contained: everything it owns lives in its directory, so
selecting it is copying one directory and setting one line.

Nothing outside the layer may name it. Entrypoint resolves by directory name;
`.agents/harness/` never mentions a specific environment.

## Provisioning is lazy

Default `JOHARNESS_ENV_SETUP=lazy`: session start reads `AGENTS.md` and stops.
No download, no daemon, no cluster. Session that never needs the environment
pays nothing.

`setup.sh` runs when someone asks — `./joharness.sh setup`, or `verify`.
Write `setup.sh` so a cold container is fine; do not assume a session-start
run happened.

`eager` provisions at session start instead, and only in the remote sandbox
(`CLAUDE_CODE_REMOTE=true`) unless `JOHARNESS_FORCE_SETUP=1`. Local machines
have their own tooling; harness does not fight it.

## md is lazy too

Same bet for context. Default `JOHARNESS_ENV_MD=lazy`: session start injects
a read-this-first pointer, not the file — session that never touches the
environment never pays context for its rules. Agent touching the environment
MUST read `.agents/env/<name>/AGENTS.md` before first command; pointer says so.
`eager` injects the file whole — worth it only if every session touches the
environment.

## Add a layer

1. `mkdir .agents/env/<name>`, write `setup.sh` (executable). Nothing to provision?
   Leave it out.
2. Rules an agent cannot read off the code go in `AGENTS.md`. Caveman style:
   [`../docs/caveman.md`](../docs/caveman.md).
3. `./joharness.sh ci` = `ci: pass`. It checks every layer, selected or not.
4. `./joharness.sh env <name>`.

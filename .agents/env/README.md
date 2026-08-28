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
| `.agents/env/<name>/ci-verify` | Declares this layer provable on a stock CI runner. Presence is the declaration; content says why, for humans. |

`ci-verify` is how a layer gets continuous coverage without any file outside
it naming it: the CI workflow globs for the marker and runs
`JOHARNESS_ENV=<name> ./joharness.sh verify` for each layer carrying one.
Lines of the form `image: <ref>` in the marker are data — every image the
layer's smoke test runs. CI pulls them with retries first, and skips that
layer loudly if the registry stays unreachable, so someone else's rate limit
never reds the gate. Declaring the marker without an executable
`smoke-test.sh` is red, the same way `verify` treats it as fatal.
Declaring it promises the layer needs nothing a stock runner lacks — `setup.sh`
downloads nothing it cannot reach and provisions no sandbox-only facility, and
`smoke-test.sh` degrades on its own where the sandbox's proxy CA bundle is
absent. A layer needing Docker-in-Docker, the egress proxy or a particular
kernel leaves the file out; verify stays the sandbox's job for it. The marker
never claims more than its own layer: it is coverage for that layer, not a
stand-in for `verify` on whichever layer a repo selects.

Layer is self-contained: everything it owns lives in its directory, so
selecting it is copying one directory and setting one line.

Nothing outside the layer may name it. Entrypoint resolves by directory name;
`.agents/harness/` mentions no specific environment — `none` excepted, which
names the absence of a layer rather than a layer. `.agents/harness/selftest.sh`
checks this and holds the single carve-out.

## One layer per consumer

Canonical carries every layer. A consumer receives ONE — the layer its own
`joharness.conf` names — plus this file. Scripts a repo never runs are dead
weight in its tree and its own `ci` shellchecks them on every push.

```bash
.agents/scripts/bootstrap-consumer.sh --env docker <dir>   # new consumer, that layer
./joharness.sh env k8s                                     # switch: select first
# then re-run the harness sync (.agents/docs/consumer-repos.md) — it brings k8s
```

Selecting a layer the consumer does not have yet is allowed and says so: the
sync reads that selection to decide what to ship, so writing it IS the
request. Until the sync runs, the repo falls back to running nothing.
Canonical refuses the same command — every layer exists there, so an unknown
name is a typo.

Layers a consumer already carries but does not select are reported by each
sync, never deleted. Remove them once: `git rm -r .agents/env/<name>`.

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
   [`.agents/docs/caveman.md`](../../.agents/docs/caveman.md).
3. `./joharness.sh ci` = `ci: pass`. It checks every layer, selected or not.
4. `./joharness.sh env <name>`.

---
plan: k8s-background-setup
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
issue: none
scope: joharness.sh, .agents/scripts/bootstrap-consumer.sh, .agents/env/README.md, .agents/docs/consumer-repos.md, .agents/harness/selftest.sh, .agents/harness/selftest/bootstrap-consumer.sh
---

## Goal

The requester wants the environment ready before a session needs it,
without the session waiting for it. Today `JOHARNESS_ENV_SETUP=lazy` makes
the first `./joharness.sh setup` wait (k8s layer: 18-33s, README § Startup
cost) and `eager` makes session start wait the same. Add a third mode,
`background`: session start launches the layer's `setup.sh` detached and
returns at once; a later `./joharness.sh setup` or `verify` waits for that
run instead of racing it. Layer-agnostic: any layer with a `setup.sh`.

## Scope

- `joharness.sh` — `JOHARNESS_ENV_SETUP` accepts `background` (config table
  line beside `lazy`/`eager`). Session start, under the same remote-sandbox
  gate as `eager` (`CLAUDE_CODE_REMOTE=true` or `JOHARNESS_FORCE_SETUP=1`),
  starts `run_setup <layer>` detached (`setsid`, stdin from `/dev/null`),
  bounded by `timeout ${JOHARNESS_SETUP_TIMEOUT:-600}`, output to
  `<git common dir>/joharness-setup/<layer>.log`, and writes
  `<layer>.status` there: `running <pid> <epoch>` at launch, `ok <epoch>`
  or `failed <rc> <epoch>` at the end. The banner says provisioning runs in
  the background, names the log, and says `./joharness.sh setup` waits for
  it. `run_setup` takes an exclusive `flock` on `<layer>.lock` in that dir
  for the whole `setup.sh` run, so a foreground `setup`/`verify` blocks
  until the background run ends, then runs `setup.sh` itself (idempotent:
  already up is a fast no-op). A foreground caller that blocks logs one
  line first: `waiting for background provisioning (log: …)`. No `flock`
  on the host: `background` degrades to `eager` with a warning.
- `.agents/scripts/bootstrap-consumer.sh` — `--env-setup` accepts
  `background` (usage text and `check_choice`).
- `.agents/env/README.md`, `.agents/docs/consumer-repos.md` — the three
  modes, when each pays, where the background log is.
- `.agents/harness/selftest.sh` — assertions, with a stub layer whose
  `setup.sh` sleeps: session start returns before the stub finishes;
  the status file goes `running` then `ok`; a concurrent
  `./joharness.sh setup` waits (its end is after the stub's end) and runs
  the stub once more; a stub that exits 3 leaves `failed 3`; outside the
  remote gate nothing launches.
- `.agents/harness/selftest/bootstrap-consumer.sh` — `--env-setup background`
  is written to the conf; a fourth value is refused.

## Assumptions

- A1: the session-start hook must return quickly and must not keep a child
  holding its stdout — evidence: `.claude/settings.json` hook runs
  `joharness.sh session-start`; a detached child with redirected fds does
  not hold it — confidence: medium. Measure hook wall time with a 20s stub.
- A2: `CLAUDE_ENV_FILE` lines written by `setup.sh` after the hook returned
  still reach later Bash calls — evidence: none; k8s `setup.sh` writes
  `KUBECONFIG` there — confidence: low. If not, `KUBECONFIG` must already
  default right (`~/.kube/config`), which the k8s layer relies on anyway;
  record what you measured.
- A3: `flock` is present in the cloud image — evidence: util-linux is in
  the image (`flock --version` in this container) — confidence: high.
- A4: a detached background `docker`/`k3d`/`k3s` run survives the hook's
  process group ending — evidence: devenv.sh already `setsid`s dockerd for
  the same reason — confidence: high.

## Out of scope

- Changing any repo's `joharness.conf` mode: a human picks `background`
  (`joharness.conf` is a core path).
- A progress UI or `setup --status` subcommand: the status file and log
  are the interface.
- Retrying a failed background run: the next foreground `setup` is the
  retry.
- Anything under a layer's own directory, scripts or docs (`.agents/env/k8s/`
  belongs to plan `k8s-k3s-direct`); `.agents/env/README.md` documents the mode for every layer.

## Acceptance

- `JOHARNESS_ENV_SETUP=background CLAUDE_CODE_REMOTE=true ./joharness.sh session-start`
  with a stub layer whose `setup.sh` sleeps 20s — returns in under 2s; the
  status file reads `running …`, later `ok …`.
- Right after that, `./joharness.sh setup` — prints the waiting line,
  returns only after the stub's first run ended, exit 0.
- `JOHARNESS_ENV_SETUP=background CLAUDE_CODE_REMOTE=true ./joharness.sh session-start`
  with this repo's k8s layer (`JOHARNESS_ENV=k8s`), then
  `JOHARNESS_ENV=k8s ./joharness.sh verify` — `8 passed, 0 failed`.
- `bash .agents/harness/selftest.sh` — the new assertions pass; each fails
  with `run_setup`'s lock removed (test for a fix must fail without it).
- `./joharness.sh ci` — `ci: pass`.
- Consumer-side check, at each consumer's next sync (this plan SHIPS): a
  consumer whose conf still says `lazy` or `eager` behaves exactly as before
  (`./joharness.sh session-start` prints the same environment lines), and
  `bootstrap-consumer.sh --env-setup background` writes
  `JOHARNESS_ENV_SETUP=background` to its conf.

## Where to look

- `joharness.sh:run_setup` — where the lock goes.
- `joharness.sh:setup_mode` — the mode read.
- `joharness.sh:JOHARNESS_ENV_SETUP|lazy|conf` — the config table line.
- `.agents/scripts/bootstrap-consumer.sh:check_choice` — the value check.
- `.agents/env/README.md:eager` — the mode docs.
- `.agents/harness/selftest.sh:setup.sh env-file quoting` — existing setup stub pattern.

## Traps

- Background command must be able to finish: bound it (`timeout`), and
  never `pgrep -f` a pattern your own command line carries.
- No second copy of a rule: the banner derives the log path from the same
  variable the launcher writes, never restates it.
- `k8s-k3s-direct` rewrites `.agents/env/k8s/`; this plan edits nothing
  there. Its acceptance runs that layer's `verify`, whichever backend is on
  `main` when it builds.

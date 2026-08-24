# Python + Rust environment

Self-contained environment for repos that are a Python package with an
optional native kernel: a project venv, the repo's own dependencies, and any
pyo3 extension it declares, built and importable.

One environment layer under [`../README.md`](../README.md). Select it with
`./joharness.sh env python-rust`; provision it with `./joharness.sh setup`.

Need containers too? [`.agents/env/docker`](../docker/README.md) is plain
Docker, [`.agents/env/k8s`](../k8s/README.md) adds a k3d cluster. This layer
has neither — it is for repos whose runtime is the interpreter.

## What you get

| Component | Source | Notes |
| --- | --- | --- |
| Python | preinstalled | 3.11.15 measured in the current image |
| uv | preinstalled | 0.8.17 measured; creates the venv, installs everything |
| cargo / rustc | preinstalled | 1.94.1 measured |
| maturin | installed by `setup` | from PyPI, into the venv |
| pytest | installed by `setup` | into the venv; repo's own pin wins |

Only maturin and pytest are downloaded, plus whatever the repo itself
declares. Measured on celluloid3 (186 tests, one pyo3 crate): ~22s cold,
~1.5s warm. The cold cost is almost entirely compiling pyo3.

## Usage

```bash
./joharness.sh setup             # once per session
.venv/bin/pytest                 # tests, with the native module importable
./joharness.sh verify            # provision, then verify end to end
```

No `activate`. Calling `.venv/bin/<tool>` is one path instead of one shell
state, and shell state does not survive between an agent's tool calls.

## What setup decides, and how

- **Venv location.** `.venv/` at the repo root, `DEVENV_VENV` overrides. One
  per repo so every session and every tool finds the same interpreter.
- **Native extensions.** Every `pyproject.toml` under the repo declaring
  `build-backend = "maturin"` is built with `maturin develop --release` and
  installed into the venv. `.venv/`, `target/`, `node_modules/` and `.git/`
  are not searched.  `DEVENV_SKIP_NATIVE=1` skips the whole step;
  `DEVENV_NATIVE_PROFILE` replaces the `--release` flag.
- **The repo's own package.** Installed editable from the root
  `pyproject.toml`, with the `dev` extra when PEP 621
  `[project.optional-dependencies]` declares one. The extra is read out of
  the file rather than guessed, because `uv pip install` only *warns* about
  an extra that does not exist — a warning nobody reads is how a missing test
  dependency turns into a red test run.
- **Root project that is itself the maturin one.** Installed by the native
  build; setup does not install it a second time.

`--release` is the default because a debug-built pyo3 kernel is slow enough
at runtime to read as a performance bug in the repo rather than a build
choice, and the reason to have a native kernel at all is speed.

## Sandbox constraints

Web sandbox = Firecracker microVM + filtering egress proxy. This layer is
mostly unaffected: everything it downloads comes from hosts already on the
proxy's `no_proxy` list, so the packages and crates arrive without the CA
dance that containers need ([`../docker/README.md`](../docker/README.md)).

- Reachable direct: `pypi.org`, `files.pythonhosted.org`, `index.crates.io`.
- `github.com` HTML pages `403`, and `/releases/latest` redirects are broken.
  A crate or wheel from a git URL is the failure case to expect; pin to a
  registry release instead.
- A `403` from any other host is egress policy. Report it, do not route
  around it.

## Notes and limits

- Everything the layer creates — `.venv/`, `target/`, the built module —
  lives in the sandbox container and is reclaimed at session end. The repo
  must gitignore `.venv/`; the harness ships no `.gitignore` (consumer-own).
- `smoke-test.sh` counts 6 checks: venv creation, a PyPI install, pytest
  reporting a pass AND a failure honestly, a cargo build and run, a crates.io
  fetch, and a pyo3 extension built by maturin that Python imports and calls.
  All six run in a scratch directory, so the repo's own venv and target dir
  are never touched. `./joharness.sh verify` runs it after provisioning.
- The smoke test pins pyo3 by minor version (`SMOKE_PYO3_VERSION` overrides).
  It exists to catch the sandbox breaking, not upstream's next release.
- No Python version management. The layer uses the interpreter the image
  ships; a repo needing another one asks for it, rather than this layer
  installing toolchains behind the session's back.

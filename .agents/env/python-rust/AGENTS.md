## Environment: Python + Rust

Not provisioned at session start. Costs nothing until asked. Need it:

```bash
./joharness.sh setup     # venv, deps, pyo3 build. ~20s cold, ~2s warm
```

Once per session. Idempotent: already-provisioned is a fast no-op, repeat
safe. python3, uv, cargo, rustc ship in sandbox image — setup only creates
the venv, installs, builds. No Docker, no Kubernetes here. Need containers?
That is `.agents/env/docker` or `.agents/env/k8s`, ask human before switching
layers.

Setup does, in order:

- `.venv/` at repo root (`uv venv`)
- tool floor into it: `maturin`, `pytest`
- every `pyproject.toml` declaring `build-backend = "maturin"`:
  `maturin develop --release`
- repo's own root `pyproject.toml`: `uv pip install -e .`, with `[dev]` extra
  when the project declares one

No activate step. Call binaries by path.

## Commands

| Command | Does |
| --- | --- |
| `./joharness.sh setup` | Create venv, install repo, build native |
| `.venv/bin/pytest` | Run tests |
| `.venv/bin/pip list` | What is installed |
| `./joharness.sh verify` | Provision, then smoke test end to end |
| `DEVENV_SKIP_NATIVE=1 ./joharness.sh setup` | Skip Rust build (pure-Python change) |
| `DEVENV_NATIVE_PROFILE=--debug ./joharness.sh setup` | Faster native build, slower module |

## Touch this layer's scripts?

Lint + test first. `shellcheck -x .agents/env/python-rust/*.sh` = zero
findings. `./joharness.sh verify` = `6 passed, 0 failed`. Trust counted
numbers, never written numbers — including this one. Image lacks shellcheck:
`apt-get install -y shellcheck`.

## Trip-wires

- `pytest` off `PATH` is system python: repo's own package and native module
  missing, import errors that look like real bugs. `.venv/bin/pytest`.
- Rust edit invisible from Python. Venv holds a BUILT module, not source.
  Rebuild: `./joharness.sh setup`.
- Native module built debug is slow enough at runtime to read as a bug. Layer
  builds `--release` for that reason. `DEVENV_NATIVE_PROFILE=--debug` when
  the edit loop matters more.
- Dev dependency not installed? Layer reads PEP 621
  `[project.optional-dependencies]` `dev` only. Anywhere else, install it
  yourself.
- Repo needs `.venv/` in `.gitignore`. Setup writes it at repo root.
- pypi.org, files.pythonhosted.org, index.crates.io reachable direct — proxy
  `no_proxy` list. Other host 403? Egress policy, do not route around.

## Persistence

Container reclaimed at session end. `.venv/`, `target/`, built modules die
too. Commit and push what matters — sources and pins, never the venv.

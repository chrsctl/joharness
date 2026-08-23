## Environment: Docker

Not provisioned at session start. Costs nothing until asked. Need it:

```bash
./joharness.sh setup     # starts dockerd. ~2s cold, no downloads
```

Once per session. Idempotent: already-running is a fast no-op, repeat safe.
docker, Compose, buildx ship in sandbox image — setup only starts daemon.
No Kubernetes here. Need a cluster? That is `env/k8s`, ask human before
switching layers.

```bash
docker build -t my-app:dev .
docker run --rm my-app:dev
docker compose up -d
```

## Commands

| Command | Does |
| --- | --- |
| `docker info` / `docker ps` | What runs |
| `./joharness.sh setup` | Start dockerd |
| `./joharness.sh verify` | Provision, then smoke test end to end |
| `tail /var/log/devenv/dockerd.log` | Daemon log when something is wrong |

## Touch this layer's scripts?

Lint + test first. `shellcheck -x env/docker/*.sh` = zero findings.
`./joharness.sh verify` = `6 passed, 0 failed`. Trust counted numbers, never
written numbers — including this one. Image lacks shellcheck:
`apt-get install -y shellcheck`.

## Trip-wires

Sandbox = Firecracker microVM + filtering egress proxy. Symptoms + full
story: [`env/docker/README.md`](env/docker/README.md).

- HTTPS from INSIDE container fails ("certificate signed by unknown
  authority", or connection reset). Proxy re-terminates TLS; container lacks
  proxy CA. Mount bundle:
  `-v /root/.ccr/ca-bundle.crt:/etc/ssl/certs/ca-certificates.crt:ro`.
- Same in `docker build` `RUN` steps doing network. COPY bundle into image
  over `/etc/ssl/certs/ca-certificates.crt` before network `RUN` steps.
- NO proxy env vars into containers. Proxy lives on host `127.0.0.1` — wrong
  address inside container. Egress intercepted transparently; CA bundle only.
- Download 403? Host blocked by egress policy. Do not route around.
  `github.com` HTML pages 403, `/releases/latest` broken — direct release
  asset URLs work. Pin versions.

## Persistence

Container reclaimed at session end. Images, volumes, running containers die
too. Commit and push what matters — Dockerfiles and compose files, never
built images.

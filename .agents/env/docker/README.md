# Docker environment

Self-contained plain-Docker environment for Claude Code on the web sessions:
build images, run containers, wire them up with Compose. The simple workflow
layer — no Kubernetes, no cluster, none of either's cost.

One environment layer under [`../README.md`](../README.md). Select it with
`./joharness.sh env docker`; provision it with `./joharness.sh setup`.

Need a cluster too? [`.agents/env/k8s`](../k8s/README.md) is Docker *plus* k3d
Kubernetes; this layer is for repos where Docker alone is the runtime.

## What you get

| Component | Source | Notes |
| --- | --- | --- |
| Docker | preinstalled | daemon started by `setup` |
| Docker Compose | preinstalled | v5.1.1 measured in the current image |
| buildx | preinstalled | default builder |

Nothing is downloaded: the sandbox image ships all three, so `setup` is
"start dockerd and wait", about 2 seconds cold, under a second when the
daemon already runs. Versions come from the image, so they move with it —
`setup` warns if Compose or buildx are missing instead of failing.

## Usage

```bash
./joharness.sh setup             # once per session
docker build -t my-app:dev .
docker run --rm my-app:dev
docker compose up -d
./joharness.sh verify            # provision, then verify end to end
```

## Sandbox constraints this works around

Web sandbox = Firecracker microVM + filtering egress proxy. Two properties
bite plain Docker here; both come from the proxy, and `.agents/env/k8s/README.md`
tells the same story for cluster nodes.

### 1. Containers need the proxy CA or HTTPS fails

The proxy re-terminates TLS; containers do not inherit the host trust store.
Any HTTPS call from inside a container — `apk add`, `pip install`, `curl` —
fails with `certificate signed by unknown authority` (or a bare connection
reset). Verified both ways in this sandbox:

```bash
docker run --rm alpine:3 wget -q https://example.com          # fails
docker run --rm \
  -v /root/.ccr/ca-bundle.crt:/etc/ssl/certs/ca-certificates.crt:ro \
  alpine:3 wget -q https://example.com                        # works
```

The bundle is the full public trust store plus the proxy CA — nothing lost by
mounting it over the container's own.

`docker build` `RUN` steps run in containers too, and a bind mount is not
available there. `COPY` the bundle into the image first:

```dockerfile
FROM alpine:3
COPY ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
RUN apk add --no-cache curl
```

with `cp /root/.ccr/ca-bundle.crt .` into the build context beforehand. Keep
that `COPY` out of images you ship; a builder stage or a dev-only Dockerfile
keeps the proxy CA from leaking into production images.

Image pulls by the daemon itself are unaffected — dockerd runs on the host
and uses the host trust store.

### 2. No proxy variables into containers

The egress proxy listens on the host's `127.0.0.1`, which inside a container
is the container itself. Passing `HTTPS_PROXY` through (`docker run -e`,
compose `environment:`) makes every connection fail with
`connection refused`. Egress is intercepted transparently — containers need
the CA bundle above and no proxy configuration at all.

### Blocked and allowed hosts

Egress policy filters by host. `github.com` HTML pages return `403` — the
`/releases/latest` redirect most install scripts follow is broken, direct
release asset URLs work, so pin versions if this layer ever needs a download.
Known reachable: `registry-1.docker.io`, `raw.githubusercontent.com`,
`dl.k8s.io`, `get.helm.sh`, `proxy.golang.org`, `registry.k8s.io`.

## Notes and limits

- Everything Docker holds — images, volumes, running containers — lives in
  the sandbox container and is reclaimed at session end. Commit and push
  what matters; rebuild the rest next session.
- `smoke-test.sh` counts 6 checks: daemon, registry pull, build, container
  egress with the CA bundle, container-to-container DNS on a user-defined
  network, and a Compose service answering. `./joharness.sh verify` runs it
  after provisioning.
- The dockerd start logic mirrors `.agents/env/k8s/devenv.sh` rather than calling
  it: layers are self-contained by contract ([`../README.md`](../README.md)),
  so neither layer may reference the other.

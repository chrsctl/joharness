---
plan: selftest-mode-marker-leak
urgency: normal
agent: sonnet
effort: low
needs: none
requirement: none
scope: .agents/harness/selftest/autonomy-mode.sh
---

## Goal

Setting the session-local mode marker reds the selftest, for a reason that
has nothing to do with anything the operator changed.

Reproduced 2026-08-31 on `main` at `77a8917`:

```
./joharness.sh mode unsupervised
bash .agents/harness/selftest.sh
  FAIL supervised session-start says nothing about mode
  1105 passed, 1 failed
```

`.agents/harness/selftest/autonomy-mode.sh` runs the real entrypoint with a
scratch `JOHARNESS_CONF` and asserts a supervised session-start prints no
`Mode:` line. But `MODE_FILE` defaults to the **real repository's**
`.git/joharness-mode`, which the marker occupies — and the marker outranks
the conf. So the case is asserting supervised behaviour on a harness that is
genuinely unsupervised, and it is right to fail; the fixture is
under-isolated.

The runner already `unset`s `JOHARNESS_MODE` and `JOHARNESS_MODE_FILE` at the
top, which is what makes this easy to miss: the ENV is neutralised and the
FILE the default resolves to is not.

Worse, `ci` hides it. On a branch whose diff is documentation only the
selftest is skipped, so `ci: pass` while the suite is red — which is exactly
how this was found: the source sweep runs `JOHARNESS_SELFTEST=always` and
reported `checks(1 failing) ci-red(exit 1)` against a green `ci`.

## Scope

- `.agents/harness/selftest/autonomy-mode.sh`: point `JOHARNESS_MODE_FILE` at
  a scratch path for the cases that run the real entrypoint, so a marker in
  the developer's own checkout cannot decide their verdict.
- Check the whole topic, not just the one case that failed. Any case reading
  the real `joharness.sh` for a mode-dependent answer has the same exposure;
  the one that failed is the one whose assertion happened to be sensitive.

## Out of scope

- The marker's own design. Living inside the git directory is deliberate and
  well-reasoned — git tracks nothing there, so it cannot reach a commit and
  does not survive a clone. The defect is the fixture's isolation, not the
  instrument.
- The docs-only selftest skip. It is a real cost-saver and its own trade-off;
  that a skipped suite can hide a red is what the source sweep is for, and it
  worked.

## Acceptance

```
./joharness.sh mode unsupervised
bash .agents/harness/selftest.sh    # 0 failed
./joharness.sh mode supervised
bash .agents/harness/selftest.sh    # 0 failed
./joharness.sh mode default
bash .agents/harness/selftest.sh    # 0 failed
```

All three, because a fixture that hardcodes "no marker" passes the third and
fails the first two. And the load-bearing one:

```
./joharness.sh mutate .agents/harness/selftest/autonomy-mode.sh <line> '<the un-isolated form>'
```

must red while the marker is set. A case green both ways pins nothing.

## Where to look

- `.agents/harness/selftest/autonomy-mode.sh` — the `refute "supervised
  session-start says nothing about mode"` case and its neighbours.
- `joharness.sh:mode_file_default` — why the default is the git directory,
  and why that is right.
- `.agents/harness/selftest.sh` — the `unset` block that neutralises the env
  and not the file.

## Traps

- Do not fix it by clearing the marker in the runner. That makes the suite
  mutate the operator's session state, and a test that edits the machine it
  runs on is worse than the flake it removes.
- `JOHARNESS_MODE_FILE` pointed at a path that EXISTS but is empty is not the
  same as pointed at an absent one; `mode_raw` reads the first word. Use an
  absent path, or assert which you meant.

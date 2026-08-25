---
plan: verify-none-layer
urgency: normal
agent: haiku
effort: low
needs: none
requirement: none
scope: joharness.sh, .agents/harness/selftest.sh
---

## Goal

`./joharness.sh verify` treats the supported `none` layer as a
misconfiguration, and Loop step 7 requires `verify`.

Counted, 2026-08-25:

```
$ JOHARNESS_ENV=none ./joharness.sh verify
[joharness] ERROR: .agents/env/none ships no smoke-test.sh
  (selected: none; try: ./joharness.sh env)
$ echo $?
1
```

`none` is not a mistake a user made. It is a first-class layer with its own
`.agents/env/none/AGENTS.md`, documented in `.agents/env/README.md` as
"harness only, no environment", and it is the layer a consumer gets when
`bootstrap-consumer.sh` runs without `--env`. The remedy the message offers —
switch environment — is advice to undo a deliberate choice.

The consequence reaches the merge rule, which is why this is worth fixing
rather than living with. Step 7 requires `verify` green whenever the diff
touches a non-`*.md` file under `joharness.sh`, `.agents/harness/`,
`.agents/env/` or `scripts/`. For an `env=none` consumer, that condition is
unsatisfiable by construction: `verify` exits 1 no matter what the diff says,
so every harness-code change is unmergeable by the letter of the rule, and
the session either stops or learns to ignore step 7. A rule that cannot be
satisfied teaches the override — the same argument
`.agents/docs/consumer-repos.md` already makes about `upgrade`'s refusal.

The harness already has the right shape for this and uses it three times:
`churn`, `review` and `fin_gate` all report and pass when they cannot see
what they need, rather than going red on what they could not prove. `none`
is that case — there is nothing to verify, which is not the same as failing
to verify.

## Scope

- `joharness.sh:cmd_verify` — a layer that ships no `smoke-test.sh` reports
  and exits 0.
- `.agents/harness/selftest.sh` — a case pinning the behaviour by name.

## Out of scope

- **The missing-layer case.** `resolve_env` failing to find the selected
  directory at all is a genuine misconfiguration and must stay an error. Only
  a layer that exists and ships no smoke test changes.
- **Writing a `smoke-test.sh` for `none`.** An empty smoke test that passes is
  a green tick nobody ran, which is the shape this harness refuses
  (`consumer-repos.md`, on merging a sync on a tick nobody ran).
- **`cmd_setup` / `run_setup`.** Provisioning `none` is already a no-op and is
  not what this plan touches.
- **Step 7's wording.** If `verify` behaves, the rule reads correctly as
  written. Do not edit `AGENTS.md` for this.

## Acceptance

- `JOHARNESS_ENV=none ./joharness.sh verify` exits **0** and prints a line
  saying there is nothing to verify and why — not silence. A command that
  passes with no output is indistinguishable from one that did not run.
- A selected layer that does not exist on disk still exits non-zero.
- A layer that exists with a non-executable `smoke-test.sh` — decide which
  case that is, make the code and the message agree, and say which in a
  comment. It is currently lumped in with "ships none" by an `[ -x ]` test.
- Both new cases named in `./joharness.sh ci` output. Prove the exit-0 case
  goes red before the fix.
- `./joharness.sh ci` — `ci: pass`.

## Where to look

- `joharness.sh:cmd_verify` — four lines; the `[ -x "$smoke" ] || die` is the
  defect.
- `joharness.sh:fin_gate`, the `not measurable here` arm — the report-and-pass
  precedent, with the comment explaining the doctrine.
- `.agents/env/none/AGENTS.md` — proof the layer is intended and supported.

## Traps

- `verify` is the one bar CI cannot run (it needs the sandbox), so its exit
  code is read by humans and by step 7, never by a workflow. Changing 1 to 0
  changes what a session is allowed to merge — which is the point, and worth
  saying out loud in the workstream file's `## Review`.
- Do not make the message advise `./joharness.sh env`. That is the wrong
  advice for this case and is half of what makes the current behaviour
  confusing.

---
plan: unsupervised-mode-gate
urgency: normal
agent: opus
effort: xhigh
needs: none
requirement: unsupervised-mode
scope: joharness.conf, joharness.sh, .agents/harness/AGENTS.md, .agents/harness/handover-guard.sh, .agents/harness/selftest.sh
---

## Goal

Everything else in `unsupervised-mode` depends on a session knowing which
mode it is in, and on the one boundary the requester kept being enforced
before any autonomy exists to test it. This plan ships the switch and its
guard together, and nothing else. It changes no behaviour for a supervised
repo — the mode reads `supervised` when the key is absent, which is every
repo today and every consumer that syncs the harness.

The rule this makes an exception to is `.agents/harness/AGENTS.md:24`: "No
issue, no requirement, no plan: ask human. Not invent work." That line
stays true and gains a named exception gated on the mode. A rule that
quietly stops meaning what it says is worse than no rule, so the carve-out
is written at the rule, not hidden in a script.

## Scope

- `joharness.conf` — `JOHARNESS_MODE=supervised`, documented in the same
  register as the `JOHARNESS_ENV_SETUP` and `JOHARNESS_ENV_MD` blocks
  above it. Note in the comment that this file is per-repo and NOT synced
  to consumers, so a consumer opting in does so deliberately.
- `joharness.sh:74` — a `run_mode()` reader beside `setup_mode()` and
  `md_mode()`, same shape: environment override first, `conf_get` second.
  Unknown or empty value resolves to `supervised`. A typo must fail
  closed, never open.
- `joharness.sh:733` — `cmd_session_start` prints the mode in the banner,
  unconditionally and in both modes. A session must be able to tell what
  it is allowed to do from injected context alone, without reading conf.
- `.agents/harness/AGENTS.md:24` — the exception, one line, gated on
  `JOHARNESS_MODE=unsupervised`, pointing at the requirement. Caveman
  (`.agents/docs/caveman.md`): this file loads every session.
- `.agents/harness/handover-guard.sh` — the guard. Under unsupervised, a
  commit touching `.agents/harness/` is refused with the reason. Runs on
  the `Stop` hook, where the guard already lives.
- `.agents/harness/selftest.sh` — mode resolution (absent key, empty
  value, typo, env override, both valid values), the banner line in both
  modes, and the guard refusing and permitting.

## Out of scope

- Any autonomous behaviour whatsoever. This plan makes the mode readable
  and the boundary enforced. Nothing acts on the mode yet: the edge path
  in `queue-context.sh` is `unsupervised-edge-work`'s, the fan-out is
  `unsupervised-fanout`'s. A session that finds itself implementing either
  here has taken both plans at once and should stop.
- A cap on work per run, a halt when main is red, and a ban on sessions
  spawning sessions. All three were offered to the requester on
  2026-08-24 and all three were declined. Do not add them back as a
  judgment call; the requirement's Constraints section records this.
- Changing what step 7 requires before a merge. The mode removes the
  human, never the gate.
- A consumer-side default. Consumers keep their own `joharness.conf`; the
  harness never picks a mode for them.

## Acceptance

- `./joharness.sh session-start` with no `JOHARNESS_MODE` key at all —
  banner reports supervised, and the rest of the output is byte-identical
  to a pre-change capture. Diff them and paste the result.
- `JOHARNESS_MODE=unsupervised ./joharness.sh session-start` — banner
  reports unsupervised.
- `JOHARNESS_MODE=nonsense ./joharness.sh session-start` — banner reports
  supervised. Fail closed, and say which value was ignored.
- Guard, unsupervised, a staged commit touching `.agents/harness/` —
  refused, and the refusal names the file and the constraint. Paste it.
- Guard, unsupervised, a commit touching only `docs/` — permitted.
- Guard, supervised, a commit touching `.agents/harness/` — permitted,
  exactly as today.
- `./.agents/harness/selftest.sh` — passes, count higher by the tests
  added.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — 7 passed, 0 failed. Required: this diff
  touches non-`*.md` files under `joharness.sh` and `.agents/harness/`.

## Where to look

- `joharness.sh:74` — `setup_mode()` and `md_mode()`, the two-line pattern
  `run_mode()` copies, and `conf_get` behind them.
- `joharness.sh:733` — `cmd_session_start`, and the `== Environment:`
  banner it prints before delegating.
- `.agents/harness/AGENTS.md:24` — the sentence gaining the exception.
- `.agents/harness/handover-guard.sh` — the existing Stop-hook guard, its
  exit conventions and how it words a refusal.
- `joharness.conf` — the two mode blocks that set the comment register,
  and the `JOHARNESS_CANONICAL` note on what is and is not synced.

## Traps

- Fail closed. An unreadable, empty or misspelled mode is supervised. The
  failure mode of failing open is an unattended fleet nobody asked for.
- Supervised output must not move by a byte. Consumers diff this file.
- `.agents/harness/` must never name a specific environment (`AGENTS.md`
  Part 2) — the mode is harness-level and stays environment-agnostic.
- The guard is on `Stop`, which fires once per stop and can be stopped
  through. It is a boundary, not a vault; say so in its refusal rather
  than implying more than it enforces.
- `unsupervised-edge-work` and `unsupervised-fanout` both declare
  `needs: unsupervised-mode-gate` and both touch
  `.agents/harness/selftest.sh`. Land this one first; they are blocked
  until this plan's file is deleted.
- Caveman applies to `AGENTS.md` and to hook output: both are paid every
  session.

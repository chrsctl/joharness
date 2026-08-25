---
plan: layer-rule-enforced
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .agents/harness/README.md, .agents/env/README.md, AGENTS.md, .agents/harness/selftest.sh
---

## Goal

The structural invariant this whole `.agents/` split exists to protect is
stated three times, absolutely, and the tree breaks it once, deliberately.
Nothing checks it.

Stated:

- `AGENTS.md:19` — "`.agents/harness/` must never name a specific environment."
- `.agents/env/README.md:29` — "`.agents/harness/` never mentions a specific
  environment."
- `.agents/harness/README.md:46` — "Nothing here names a specific environment."

Counted, 2026-08-25: `.agents/harness/selftest.sh` names `k8s` six times
(lines 198–237), running a real regression test against
`.agents/env/k8s/setup.sh` — a hostile cluster name executing when the env
file is sourced.

**The exception is right.** That defect is worth a git-only test, a layer's
own `smoke-test.sh` needs the sandbox that CI does not have, and the block
already degrades correctly where the layer is absent (`skip`, not `fail`,
because consumers receive one layer). Do not delete that test. This plan
does not reopen the decision; it makes the decision visible.

The defect is that the argument lives **only** in a code comment 206 lines
into a 3,152-line file, while the file whose entire job is describing that
directory says the opposite in five words. This repo writes for literal
readers as policy. A session that reads `.agents/harness/README.md` and then
greps has two moves available and both are wrong: delete a security
regression test, or add a second undocumented exception on the precedent of
the first.

`.agents/docs/feedback.md`'s own test applies: does the fact it states match
what it measures? Here, no — and unlike the guard wording it names, this one
has no gate that would ever catch the drift.

## Scope

- `.agents/harness/README.md` — the sentence at line 46, made true. It
  describes this directory's contents; it is the one that must carry the
  carve-out, not merely permit it.
- `.agents/env/README.md` and root `AGENTS.md` — the same rule, kept
  consistent with whatever wording wins. Three statements of one rule that
  drift apart is the next defect.
- `.agents/harness/selftest.sh` — the check that makes the rule real: no file
  under `.agents/harness/` names a layer directory, except the carve-out,
  named explicitly.

## Out of scope

- **Deleting or relocating the k8s test.** It is correct where it is and the
  Goal says why. A plan that quietly moves it has changed a security test's
  coverage while claiming to fix documentation.
- **The `.agents/env/` → harness direction.** A layer naming the harness is
  fine and normal; only the reverse coupling is the bug.
- **Auditing `.agents/docs/` for environment names.** Docs discuss layers by
  necessity — `consumer-repos.md` and `.agents/env/README.md` both name `k8s`
  legitimately. The rule is about `.agents/harness/`.
- **A general "no cross-layer reference" lint.** One rule, one check. The
  broader sweep is a different plan with a different argument.

## Acceptance

- The new check goes RED against today's tree with the carve-out removed from
  its allowlist, and GREEN with it. Prove both directions — a check that only
  ever passes is the failure mode this whole plan is about.
- A fixture adding `docker` or `python-rust` to a file under
  `.agents/harness/` fails the check by name, naming the file and the layer.
- The carve-out is spelled once, in one place the check reads, not repeated
  in three files that can drift.
- All three rule statements and the selftest agree when read cold. A reader
  who greps after reading any one of them finds what it predicted.
- `./joharness.sh ci` — `ci: pass`. Trust the counted number.

## Where to look

- `.agents/harness/selftest.sh`, `step ".agents/env/k8s/setup.sh env-file
  quoting"` and the comment block above it — the exception, and the best
  existing statement of why it exists. That comment is the raw material for
  the doc change.
- `.agents/harness/README.md`, the "Nothing here names a specific
  environment" paragraph.
- `joharness.sh:check_targets` — the existing precedent for a check that
  walks every harness-owned script from one find root.

## Traps

- The rule is load-bearing for the sync engine's layer split, so a wording
  change that accidentally widens it (from "names a layer" to "references
  `.agents/env/`") makes `.agents/env/README.md` — which ships — unmentionable
  from the harness layer. Keep the rule about layer NAMES.
- `selftest.sh` is canonical-only and never ships. That is a reason the
  carve-out is cheap, and it is NOT a reason to exempt the file from the
  check: the rule is about coupling, and a consumer that already carries a
  legacy copy still reads it.
- Trust counted numbers, never written numbers — the six occurrences above
  included. Re-count before relying on them.

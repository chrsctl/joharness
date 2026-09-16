---
plan: num-knob-digits
urgency: normal
agent: sonnet
effort: high
needs: none
requirement: none
scope: joharness.sh, shared:.agents/harness/selftest.sh, .agents/harness/selftest/num-knob.sh
---

## Goal

Issue #260. `num_knob` filters its value to digits only and hands the result
to bash arithmetic. `08` and `09` are digits only, so they pass the filter
and then die on the octal literal rule; `010` passes and is silently read as
eight. Every knob the harness has goes through this one reader, including
`JOHARNESS_MAX_MANAGERS`, which is the cap, which is the human's money. The
crash half lands mid-output: `dispatch` printed its header and its in-flight
rows and then exited 1 before the slots line and the verdict, leaving the
orchestrator's one branch point missing with only the exit status to say so.

## Scope

- `joharness.sh` — `num_knob`, and only it. Strip leading zeros after the
  digit filter and before the value is returned, so every caller is covered
  at once rather than each one guarding itself. The shape is the one PR #259
  used in `cmd_dispatch` for `JOHARNESS_PENDING_SPAWNS`, which hit this
  defect and fixed it in its own reader:

  ```sh
  v="${v#"${v%%[!0]*}"}"
  [ -n "$v" ] || v=0
  ```

  Then the upper bound, which is the other half of the same untrusted-digits
  question and is DECIDED BY THIS PLAN rather than left open: a value whose
  digit count exceeds a small ceiling falls back to the caller's default,
  the same answer the filter already gives a non-digit. Falling back, not
  clamping — PR #259 clamped because its input had an obvious ceiling (the
  cap); a knob has none, and a clamp to an invented number would be a
  guess printed as a setting. `dispatch` prints every knob it reads, so a
  value that fell back is visible where a reader already looks.

- `.agents/harness/selftest/num-knob.sh` — the topic file. `num_knob` is
  reached through the commands that read knobs, so the cases drive
  `./joharness.sh dispatch` under `JOHARNESS_MODE=orchestrated` and read the
  knob lines it prints, which is what `.agents/harness/selftest/dispatch.sh`
  already does for the cap and the churn knobs.

- `.agents/harness/selftest.sh` — register the topic. It is the registry
  every topic appends to, hence `shared:` in `scope:`.

## Out of scope

- Every caller's own arithmetic. The point of fixing the one reader is that
  no caller needs a guard; adding them anyway leaves two places that can
  disagree about what a knob means.
- `JOHARNESS_PENDING_SPAWNS`. It does not go through `num_knob` — by
  decision, recorded in PR #259 — and it already carries its own strip and
  its own clamp with cases pinning both. Touching it here would re-open a
  decision this plan has no argument against.
- Non-numeric knobs (`JOHARNESS_ENV`, `JOHARNESS_MODE`, `JOHARNESS_REVIEW`,
  `JOHARNESS_CHECKS`). Different readers, different validation, no octal.
- Any change to what the knobs mean, what their defaults are, or which of
  them `joharness.conf` seeds.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `JOHARNESS_CHURN_THRESHOLD=08 JOHARNESS_MODE=orchestrated ./joharness.sh dispatch`
  exits 0 and prints a `loop      :` line reading 8 and 16. Before this
  change the same command prints `value too great for base` and exits 1;
  assert the exit status, not only the text, because a command that prints
  the right line and then dies is the defect.
- `JOHARNESS_MAX_MANAGERS=010 JOHARNESS_MODE=orchestrated ./joharness.sh dispatch`
  prints `cap       : 10 manager(s)`. This is the quiet half and it needs a
  positive assertion: before the change the same command prints 8, which is
  a green run and a wrong cap.
- A value past the digit ceiling falls back to the default, asserted in both
  directions: the knob line names the default, and a value one digit under
  the ceiling is still honoured. A ceiling asserted only from above passes
  when it is set to zero.
- Each guard proved by REVERTING it, per Loop step 5: removing the strip
  reds the two cases above, removing the ceiling reds the fallback case, and
  no two mutations red the same case. Report the counts with the command and
  the date.
- SHIPS: `joharness.sh` reaches every consumer, so name a consumer-side
  check. In a consumer, `JOHARNESS_MAX_MANAGERS=010 ./joharness.sh dispatch`
  under orchestrated mode prints a cap of 10. The selftest tree is
  canonical-only and ships nowhere, so the topic file cannot cover this.

## Where to look

- `joharness.sh:num_knob` — the one reader, five lines, and the `case` that
  lets the bad values through.
- `joharness.sh:cmd_dispatch` — the caller that reproduces the crash
  fastest, at the line deriving `JOHARNESS_CHURN_LIMIT` from the threshold,
  and also the command that PRINTS every knob it read, which is what makes a
  fallback visible.
- `.agents/harness/selftest/dispatch.sh` — the existing knob cases, which
  show the `env`-per-invocation fixture idiom to copy.

## Traps

- Digits-only is not a number. The filter that looks like validation is the
  thing that let both values through, so a fix that adds a second filter of
  the same shape has not moved.
- Never widen a knob's meaning to make a case pass. If a value cannot be
  read, the default is the answer the reader already gives non-digits.
- A test written for this must FAIL without the fix. Both defects are silent
  in one direction — `010` reads as 8 with no error at all — so an assertion
  that only checks for the absence of a crash pins nothing.

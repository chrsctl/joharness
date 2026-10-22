---
plan: parser-edge-fixes
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
issue: none
scope: shared:joharness.sh, .agents/harness/selftest/feedback.sh, .agents/harness/selftest/review.sh, .agents/harness/selftest/checks.sh, .agents/harness/selftest/role.sh
---

## Goal

Small parsing and invocation defects found by the harness review (session
2026-10-22). Each gives a wrong count, a false red or a misleading message;
none is dangerous alone. Fix them together.

## Scope

All in `joharness.sh`:

- `fb_marker` — match `(fixed…)`, `(wontfix…)`, `(no change)` only as the
  finding's trailing marker (end of line), not anywhere in the text.
- `fb_findings` and `review_marks` — fold continuation lines indented by 2
  or more spaces, or a tab, into the bullet (today exactly 2 spaces).
- `issue_verdict` — strip leading zeros only: replace `${iss##*0}` with
  `n=${iss#\#}; n=${n#"${n%%[!0]*}"}`.
- The five `grep -q '^JOHARNESS_CANONICAL=1'` sites — replace with one
  `is_canonical() { [ "$(conf_get JOHARNESS_CANONICAL)" = 1 ]; }`.
- `FB_LIMIT` (`JOHARNESS_FEEDBACK_EDGES`) — validate as digits like
  `FB_WINDOW`; a non-number reads as the default.
- `ci_churn` — `JOHARNESS_CHURN_THRESHOLD=0` lifts the warning as the
  comment says (today it fires always).
- `checks_gate` `"$0" ci` / `"$0" verify` — use `"${ROOT}/joharness.sh"` as
  `cmd_free` does.
- `role_line` — avoid `printf | grep -m1` under `pipefail` (use `grep -m1
  … <<<"$text"` or `awk` with `exit`), so a large report cannot yield 141.
- `fb_cache_save` — replace the `eval "printf …"` with
  `printf '%s=%s\n' "$v" "${!v}"`.
- One selftest case per fix in the listed selftest files, each red on
  `main` first.

## Out of scope

- Refactoring `lint_finding_markers` / `lint_finding_ids` (noted as
  duplicated; separate decision).
- Any change to finding marker vocabulary.

## Acceptance

- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- `bash joharness.sh finish` (no `./`) on a clean branch does not print
  `ci: FAILED` because of 127.
- New cases red without the change; recorded in `## Review`.
- Plan `ci` calls SHIPS: the selftests run in every consumer's `ci`.

## Where to look

- `joharness.sh:fb_marker`, `fb_findings`, `review_marks`, `issue_verdict`,
  `conf_get`, `ci_churn`, `checks_gate`, `cmd_free`, `role_line`,
  `fb_cache_save`, `fb_cache_load`; `grep -n "JOHARNESS_CANONICAL=1" joharness.sh`.

## Traps

- Other queued plans edit `joharness.sh` (`shared:`); merge `origin/main` in.
- NEVER skip, disable or quarantine a test. No core paths.

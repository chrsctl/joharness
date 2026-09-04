---
plan: license-notice
urgency: normal
agent: sonnet
effort: medium
needs: none
requirement: none
scope: .agents/LICENSE, .agents/NOTICE, .agents/scripts/sync-to-consumer.sh, .agents/scripts/bootstrap-consumer.sh, .agents/harness/selftest.sh, .agents/harness/selftest, .agents/docs/caveman.md, .agents/docs/graph.md, .agents/docs/prior-art.md, .agents/harness/README.md, .agents/docs/consumer-repos.md, README.md
---

## Goal

Human asked, verbatim: "Verify that alle pieces Matches licensing also when
distilled if not fix. And attribution." Two directions. Inbound: text this
repo distilled from other projects must carry the notice those projects'
licenses require. Outbound: the harness files the sync distils into a
consumer must carry this repo's own MIT notice, which `LICENSE` line 11
requires in every copy or substantial portion and which today no consumer
receives.

## Scope

- `.agents/LICENSE` — byte-identical copy of root `LICENSE`. Ships with the
  harness; lands beside the files it covers, never at a consumer's root.
- `.agents/NOTICE` — what the grant covers in a consumer (the synced set,
  nothing else), plus third-party notices: JuliusBrussee/caveman (MIT,
  Julius Brussee) for `.agents/docs/caveman.md`, gastownhall/gastown (MIT,
  Steve Yegge) for the quotations in `.agents/docs/prior-art.md`,
  codejunkie99/graph-engineering (MIT, codejunkie99) for the rules
  `.agents/docs/graph.md` adapts.
- `.agents/scripts/sync-to-consumer.sh` — both files join `FILES`.
- `.agents/scripts/bootstrap-consumer.sh` — whole-clone mode warns that a
  root `LICENSE` is still joharness's, the same shape as its README warning;
  fresh mode's next steps say the root license is the consumer's own choice.
- `.agents/harness/selftest/sync-to-consumer.sh`,
  `.agents/harness/selftest/bootstrap-consumer.sh` — fixtures carry the two
  files; assertions that they ship, that a root `LICENSE` is never seeded,
  and that the whole-clone warning fires.
- `.agents/harness/selftest/license-notice.sh` (+ `SELFTEST_TOPICS`) — root
  and shipped license byte-identical; `caveman.md` carries its upstream's
  copyright line, because that file can be copied on its own.
- `.agents/docs/caveman.md`, `.agents/docs/prior-art.md`,
  `.agents/docs/graph.md` — upstream holder and license named where the
  material is used, pointing at the NOTICE.
- `README.md`, `.agents/harness/README.md`, `.agents/docs/consumer-repos.md`
  — the shipped notice named where the shipped set is listed.

## Out of scope

- Per-file SPDX headers. Same reason as the license plan: harness files land
  in trees licensed by the consumer, a header would misstate that.
- Deleting a whole clone's root `LICENSE` in `bootstrap-consumer.sh`. A
  consumer may keep MIT on purpose; warn like README, never delete.
- Adding root `LICENSE` to `FILES`. Overwrites a consumer's own license on
  every sync — the reason the previous plan rejected it stands.
- Notices for tools the environment layers download at provisioning time
  (kubectl, helm, k3d). Not distributed by this repo; one line in the
  NOTICE says so.

## Acceptance

- `cmp LICENSE .agents/LICENSE && echo same` — prints `same`.
- `grep -c 'Julius Brussee' .agents/NOTICE .agents/docs/caveman.md` — both
  counts at least 1.
- `./joharness.sh ci` — `ci: pass`.
- `./joharness.sh verify` — `0 failed`.
- SHIPS: `.agents/LICENSE` and `.agents/NOTICE` arrive at every consumer on
  its next sync. Consumer-side check: `ls .agents/LICENSE .agents/NOTICE`
  after `./joharness.sh upgrade`; the selftest's sync fixture proves the
  same path here.

## Where to look

- `.agents/scripts/sync-to-consumer.sh:FILES` — where a file pinned to no
  synced directory is listed.
- `.agents/scripts/bootstrap-consumer.sh:bootstrap_whole_clone` — the
  README warning this plan mirrors.
- `.agents/harness/selftest/sync-manifest-eol-pins.sh` — why nothing in
  `.gitattributes` changes: `.agents/**` is already pinned.
- `.agents/docs/caveman.md` — the distilled file; its header is the
  attribution.

## Traps

- Never write the pass count into a doc; read what `ci` and `verify` print.
- Retire this plan and the workstream file in the last commit BEFORE the
  pull request opens, never after the merge.
- `LICENSE` text stays byte-exact MIT; the scope explanation goes in NOTICE.

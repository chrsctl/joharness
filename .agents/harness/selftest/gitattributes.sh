# .gitattributes — one selftest topic, sourced by ../selftest.sh in the
# order that file lists.
#
# Not runnable alone and not meant to be: the runner defines the
# assertion helpers, the counters and the shared fixtures, and sourcing
# is inlining — a topic that builds state a later topic reads behaves
# exactly as it did when they shared one file.
# shellcheck shell=bash

# --- .gitattributes: scripts and markdown stay LF --------------------------
# Git for Windows defaults to core.autocrlf=true. Without the pins a stock clone
# there checks out scripts as CRLF (shellcheck SC1017 on every line) and
# workstream files too, emptying the frontmatter the handover hook reads. The
# scratch repo sets that default explicitly, so these fail on any platform.
step ".gitattributes"

crlf="${TMP}/crlfrepo"
git init -q "$crlf"
git -C "$crlf" config core.autocrlf true
cp "${ROOT}/.gitattributes" "${crlf}/.gitattributes" 2>/dev/null
printf '#!/usr/bin/env bash\necho probe\n' >"${crlf}/probe.sh"
# Frontmatter is the markdown that breaks: fields() exits on any line 1 not
# exactly `---`, so a CRLF checkout reports every field empty.
printf -- '---\nstatus: in-progress\n---\n\nbody\n' >"${crlf}/probe.md"
# Files no suffix pattern pins need their own path pins. `upgrade` compares
# working-tree bytes between the canonical clone and the consumer, so a
# CRLF checkout of a shipped file means phantom updates on every Windows
# run — .claude/settings.json and .gitattributes itself were the two that
# showed.
mkdir -p "${crlf}/.claude"
printf '{\n  "probe": true\n}\n' >"${crlf}/.claude/settings.json"
commit_all "$crlf" "probe"

# Re-materialize from the index: the checkout applies the attributes.
rm -f "${crlf}/probe.sh" "${crlf}/probe.md" "${crlf}/.claude/settings.json" "${crlf}/.gitattributes"
git -C "$crlf" checkout -q -- probe.sh probe.md .claude/settings.json .gitattributes ||
  fail "CRLF fixture re-checkout succeeds"

# Not `grep $'\r'`: Git Bash opens files in text mode and drops the CR before
# the pattern ever sees it, so that spelling reports clean on the one platform
# this case exists for. Stripping and comparing is byte-exact everywhere.
has_cr() { [ "$(tr -dc '\r' <"$1" | wc -c)" -gt 0 ]; }

# <path> <what>: file must come out of the checkout with no CRs. A missing
# file is a fixture bug, not a clean file — has_cr on nothing counts 0 CRs,
# which once turned a failed checkout into four green lines.
check_lf() {
  if [ ! -f "$1" ]; then
    fail "$2 checks out LF under core.autocrlf=true"
    printf '    %s missing from the checkout; fixture setup failed\n' "${1##*/}"
  elif has_cr "$1"; then
    fail "$2 checks out LF under core.autocrlf=true"
    printf '    %s came back CRLF; pinned in .gitattributes?\n' "${1##*/}"
  else
    pass "$2 checks out LF under core.autocrlf=true"
  fi
}

check_lf "${crlf}/probe.sh" "shell script"
check_lf "${crlf}/probe.md" "markdown"
check_lf "${crlf}/.claude/settings.json" "settings.json (path pin)"
check_lf "${crlf}/.gitattributes" ".gitattributes itself"

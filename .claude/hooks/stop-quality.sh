#!/bin/bash
# Stop hook: keeps the working tree consistent with what CI expects.
# - Formats Kotlin sources when any .kt file changed.
# - Regenerates the EPUB navigator script bundles when their sources changed.
set -u
cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}" || exit 0

# Prevent an infinite loop when the hook itself blocked the previous stop.
input=$(cat)
if printf '%s' "$input" | grep -q '"stop_hook_active": *true'; then
    exit 0
fi

changed=$(git status --porcelain)

if printf '%s\n' "$changed" | grep -qE '\.kts?$'; then
    make format >/dev/null 2>&1
fi

if printf '%s\n' "$changed" | grep -q 'readium/navigator/src/main/assets/_scripts/'; then
    if ! output=$(make scripts-legacy 2>&1); then
        echo "The legacy EPUB navigator scripts changed but 'make scripts-legacy' failed. Fix the errors below, the bundled scripts must be regenerated before finishing:" >&2
        echo "$output" | tail -50 >&2
        exit 2
    fi
fi

if printf '%s\n' "$changed" | grep -q 'readium/navigators/web/internals/scripts/'; then
    if ! output=$(make scripts-new 2>&1); then
        echo "The new web navigator scripts changed but 'make scripts-new' failed. Fix the errors below, the bundled scripts must be regenerated before finishing:" >&2
        echo "$output" | tail -50 >&2
        exit 2
    fi
fi

exit 0

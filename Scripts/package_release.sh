#!/usr/bin/env bash
# Binary distribution is disabled while OzDoro is source-only.
set -euo pipefail
printf '%s\n' 'Binary packaging, Developer ID signing and notarization are disabled.' >&2
printf '%s\n' 'See Docs/RELEASING.md for the approval-gated source release process.' >&2
exit 1

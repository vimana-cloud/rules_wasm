#!/usr/bin/env bash

# Run this script from the root directory of the Bazel module.
#
# Continuously tries to run a 'predicate' test
# to verify remote dependency checksums in a `module` file.
# Checksum failures are expected to contain the follow string:
#
#     Checksum was <actual> but wanted <expected>
#
# This script finds those messages, parses them,
# and edits the module file in-place to use the new, actual checksum
# instead of the previous expected checksum.

module='MODULE.bazel'
predicate='//tests:fetch-all-remotes'

while {
  bazel test "$predicate" 2>&1 \
    | sed -n 's/.*Checksum was \([^ ]*\) but wanted \([^ ]*\)/\1 \2/p' \
    | uniq \
    | {
      read -r actual expected && {
        echo >&2 "$expected → $actual"
        # BSD `sed` (used on Mac) does not support in-place editing without a backup.
        # Instead, use a temporary file (which eliminates any risk of backup filename collision).
        # Use `cp` instead of `mv` to preserve file permissions while overwriting the original.
        # (BSD `chmod` doesn't support `--reference`).
        updated="$(mktemp)"
        < "$module" sed "s.${expected}.${actual}." > "$updated" \
          && cp "$updated" "$module" \
          && rm "$updated"
      }
    }
  }
do continue
done

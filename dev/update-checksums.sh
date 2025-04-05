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
predicate='//test:fetch-all-remotes'

while {
  bazel test "$predicate" 2>&1 \
    | sed -n 's/.*Checksum was \([^ ]*\) but wanted \([^ ]*\)/\1 \2/p' \
    | uniq \
    | {
      read -r actual expected && {
        echo >&2 "$expected → $actual"
        sed -i "s.$expected.$actual." "$module"
      }
    }
  }
do continue
done

#!/usr/bin/env bash

# Invoke `wit-bindgen-go`, then generate a minimal `go.mod` file in the output directory
# so it can be imported like a normal Go module.

wit_bindgen_go="$1"
src="$2"
world="$3"
module="$4"
package_root="$5"
out="$6"

# `--package-root` must be explicitly supplied,
# otherwise `wit-bindgen-go` will try to look for a `go.mod` file.
"$wit_bindgen_go" generate "$src" \
  --world "$world" \
  --package-root "$package_root" \
  --out "$out" || exit $?

# Generate a minimal `go.mod` file in the generated directory.
cat > "$out/go.mod" <<EOF
module $module
EOF

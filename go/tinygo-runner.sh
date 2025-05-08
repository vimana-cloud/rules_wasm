#!/usr/bin/env bash

# Invoke TinyGo in an environment in which it can function, meaning:
#
# - It can find `go` in `$PATH`.
#   https://github.com/tinygo-org/tinygo/blob/v0.37.0/goenv/goenv.go#L69
# - The sandbox in which `tinygo` runs has a `go.mod` file
#   pointing to all the relevant dependencies.
# - It can find a cache directory under `$HOME`.
#   https://github.com/tinygo-org/tinygo/blob/v0.37.0/goenv/goenv.go#L149

tinygo="$1"
go="$2"
wasm_tools="$3"
output="$4"
bindings="$5"
wit="$6"
wit_module_name="$7"
cm_source_directory="$8"
cm_module_name="$9"
cm_module_version="${10}"
world="${11}"
shift 11

go_dir="$(dirname "$(realpath "$go")")"
path="${go_dir}${PATH:+:${PATH}}"
wasm_tools="$(realpath "$wasm_tools")"

cat > go.mod <<EOF
module main

go $("$go" env GOVERSION | tail -c +3)

require (
    $wit_module_name v0.0.0
    $cm_module_name v$cm_module_version // indirect
)

replace $wit_module_name => ./$bindings
replace $cm_module_name => ./$cm_source_directory
EOF

# Set up a temporary cache dir for TinyGo (effectively disabling caching).
# Do it by setting up a fake `$HOME` directory with the right shape to support either Linux or Mac.
# https://github.com/golang/go/blob/go1.24.3/src/os/file.go#L487
tmp_home="$(mktemp -d)"
if [[ "$(uname)" == "Darwin" ]]; then
  tmp_cache="$tmp_home/Library/Caches"
else
  tmp_cache="$tmp_home/.cache"
fi
mkdir -p "$tmp_cache"

HOME="$tmp_home" PATH="$path" WASMTOOLS="$wasm_tools" \
  exec "$tinygo" build --target=wasip2 --wit-package="$wit" --wit-world="$world" -o "$output" "$@"

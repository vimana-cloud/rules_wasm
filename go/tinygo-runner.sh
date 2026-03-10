#!/usr/bin/env bash

# Invoke TinyGo in an environment in which it can function, meaning:
#
# - It can find `go` in `$PATH`.
#   https://github.com/tinygo-org/tinygo/blob/v0.39.0/goenv/goenv.go#L69
# - The sandbox in which `tinygo` runs has a `go.mod` file
#   pointing to all the relevant dependencies.
# - It can find a cache directory under `$HOME`.
#   https://github.com/tinygo-org/tinygo/blob/v0.39.0/goenv/goenv.go#L149

tinygo="$1"
go="$2"
wasm_tools="$3"
wasm_opt="$4"
jq="$5"
output="$6"
bindings="$7"
wit="$8"
wit_module_name="$9"
cm_source_directory="${10}"
cm_module_name="${11}"
cm_module_version="${12}"
world="${13}"
main_package="${14}"
shift 14

# Remaining args are pairs of: <importpath> <src_dir>
dep_importpaths=()
dep_packages=()
while [[ $# -ge 2 ]]
do
  dep_importpaths+=("$1")
  dep_packages+=("$2")
  shift 2
done

go_dir="$(dirname "$(realpath "$go")")"
tiny_go_root="$(dirname "$(dirname "$(realpath "$tinygo")")")"
wasm_tools="$(realpath "$wasm_tools")"
wasm_opt="$(realpath "$wasm_opt")"

# `go env GOVERSION` prints something like `go1.26.0`
# so use `tail` to strip the first 2 characters, which should always be `go`.
go_version="$("$go" env GOVERSION | tail -c +3)"

# Create a dummy `go.mod` file for the main module and each dependency module.
# Dependencies are resolved via the `go.work` file.
printf 'module main\n\ngo %s\n' "$go_version" > go.mod
for i in "${!dep_importpaths[@]}"
do
  printf 'module %s\n\ngo %s\n' "${dep_importpaths[$i]}" "$go_version" > "${dep_packages[$i]}/go.mod"
done

# The `go:embed` directive uses lstat and will not follow symlinks,
# but Bazel exposes sandbox inputs as symlinks.
# Replace any symlinks in dependency directories with their targets.
# https://pkg.go.dev/embed
for package in "${dep_packages[@]}"
do
  while IFS= read -r -d '' link
  do
    real="$(readlink -f "$link")"
    if [[ -f "$real" ]]
    then
      # A simple `cp "$real" "$link"`
      # would cause `cp` to follow the destination symlink rather than overwrite it.
      cp "$real" "${link}.tmp" && mv "${link}.tmp" "$link"
    fi
  done < <(find "$package" -type l -print0)
done

# Create a `go.work` file so TinyGo uses workspace mode,
# which lets all modules in a dependency tree resolve each other
# without explicit require / replace entries.
{
  echo "go $go_version"
  echo ""
  echo "use ."
  echo "use ./$bindings"
  echo "use ./$cm_source_directory"
  for package in "${dep_packages[@]}"
  do
    echo "use ./$package"
  done
} > go.work

# Set up a temporary cache dir for TinyGo (effectively disabling caching).
# Do it by setting up a fake `$HOME` directory with the right shape to support either Linux or Mac.
# https://github.com/golang/go/blob/go1.24.3/src/os/file.go#L487
tmp_home="$(mktemp -d)"
if [[ "$(uname)" == 'Darwin' ]]
then
  tmp_cache="$tmp_home/Library/Caches"
else
  tmp_cache="$tmp_home/.cache"
fi
mkdir -p "$tmp_cache"

HOME="$tmp_home" \
  PATH="${go_dir}${PATH:+:${PATH}}" \
  TINYGOROOT="$tiny_go_root" \
  WASMTOOLS="$wasm_tools" \
  WASMOPT="$wasm_opt" \
  exec "$tinygo" build \
    --target=wasip2 \
    --wit-package="$wit" \
    --wit-world="$world" \
    -o "$output" \
    "$main_package"

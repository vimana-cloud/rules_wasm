# Wasm Component Bazel Tools

A Bazel module with tools
for working with [WebAssembly components](https://component-model.bytecodealliance.org/).

## Rules

- [`//:wasm.bzl`](wasm.bzl):
  * `wasm_component` - Turn a core Wasm module into a component.
  * `wit_package` - Bundle a group of WIT files into a unified package.
- [`//:rust.bzl`](rust.bzl):
  * `rust_component` - Compile a Wasm interface and matching Rust implementation
    into a component (macro).
  * `rust_wit_bindgen` - Generate Rust sources for a Wasm interface.

## Examples

See [`test/BUILD.bazel`](test/BUILD.bazel).

## Caveats

- Currently works only when the execution platform is `x86_64-linux`.
  This might be easily fixed
  by doing something more sophisticated than hard-wiring the platform
  in [`MODULE.bazel`](MODULE.bazel).
  Pre-built binaries generally exist for MacOS as well.
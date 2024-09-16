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

See [`examples/BUILD.bazel`](examples/BUILD.bazel).

## Caveats

- Currently works only for the following execution platforms
  (due to downloading pre-built binaries):
  * `aarch64-linux`
  * `aarch64-macos`
  * `x86_64-linux`
  * `x86_64-macos`

## Todo

- Add a rule for [Wasm compositions](https://github.com/bytecodealliance/wac).

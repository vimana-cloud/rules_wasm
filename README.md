# WebAssembly Component Bazel Tools

A Bazel module with tools
for working with [WebAssembly components](https://component-model.bytecodealliance.org/).

This module primarily hosts
language-agnostic rules for working with WebAssembly components,
but also welcomes language-specific rules to compile source code files into components
(including generating WIT bindings).

## Rules

- [`//:wasm.bzl`](wasm.bzl):
  * `wasm_component` - Turn a core Wasm module into a component.
  * `wasm_plug` - Link the exports of a 'plug' component
    into the imports of a 'wrapper' component to create a new component.
    This is the simplest way to compose components together
    without a [WAC](https://github.com/bytecodealliance/wac) file.
  * `wit_package` - Bundle a group of WIT files into a unified package.
- [`//:rust.bzl`](rust.bzl):
  * `rust_component` - Compile a Wasm interface and matching Rust implementation
    into a Wasm component.
  * `rust_wit_bindgen` - Generate Rust sources for a Wasm interface.
    This is a lower-level rule that you normally wouldn't need to use directly.
    Use `rust_component` for a single macro to compile a component from Rust.

## Examples

See [`example/BUILD.bazel`](example/BUILD.bazel).

## Caveats

- Currently works only for the following execution platforms
  (due to a dependency on Bash and downloading pre-built binaries):
  * `aarch64-linux`
  * `aarch64-macos`
  * `x86_64-linux`
  * `x86_64-macos`

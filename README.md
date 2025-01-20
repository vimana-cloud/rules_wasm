# WebAssembly Component Bazel Tools

A Bazel module with tools
for working with [WebAssembly components](https://component-model.bytecodealliance.org/).

This module primarily hosts
language-agnostic rules for working with WebAssembly components,
but also welcomes language-specific rules to compile source code files into components
(including generating WIT bindings).

## Rules

- [`//wasm:defs.bzl`](wasm/defs.bzl):
  * `wasm_component` - Turn a core Wasm module into a component.
  * `wasm_plug` - Link the exports of a 'plug' component
    into the imports of a 'wrapper' component to create a new component.
    This is the simplest way to compose components together
    without a [WAC](https://github.com/bytecodealliance/wac) file.
  * `wit_package` - Bundle a group of WIT files into a unified package.
- [`//rust:defs.bzl`](rust/defs.bzl):
  * `rust_component` - Compile a Wasm interface and matching Rust implementation
    into a Wasm component.
  * `rust_wit_bindgen` - Generate Rust sources for a Wasm interface.
    This is a lower-level rule that you normally wouldn't need to use directly.
    Use `rust_component` for a single macro to compile a component from Rust.
- [`//c:defs.bzl`](c/defs.bzl):
  * `c_component` - Compile a Wasm interface and matching C implementation
    into a Wasm component.
  * `c_wit_bindgen` - Generate C sources for a Wasm interface.
    This is a lower-level rule that you normally wouldn't need to use directly.
    Use `c_component` for a single macro to compile a component from C.
- Go support is hacky and needs to be adapted to a proper Go toolchain.
  This is [fundamentally difficult](https://github.com/bazel-contrib/rules_go/issues/4333)
  because Bazel's Go rules require knowing about module metadata and dependencies
  during the analysis phase,
  but the output of `wit-bindgen-go` is only known for sure during the execution phase.
  Meanwhile, there's [`//go:defs.bzl`](go/defs.bzl),
  which makes use of [TinyGo](https://tinygo.org/):
  * `go_component` - Compile a Wasm interface and matching C implementation
    into a Wasm component.
  * `go_wit_bindgen` - Generate Go sources for a Wasm interface,
    including a minimal `go.mod` file to emulate a Go module.
    This is a lower-level rule that you normally wouldn't need to use directly.
    Use `go_component` for a single macro to compile a component from Go.

## Examples

See [`example/`](example/).

## Caveats

- Currently works only for the following execution platforms
  (due to a dependency on Bash and downloading pre-built binaries):
  * `aarch64-linux`
  * `aarch64-macos`
  * `x86_64-linux`
  * `x86_64-macos`

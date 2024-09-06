# Wasm Component Bazel Tools

A Bazel module with tools
for working with [WebAssembly components](https://component-model.bytecodealliance.org/).

## Examples

See [`test/BUILD.bazel`](test/BUILD.bazel).

## Caveats

- Currently works only when the execution platform is `x86_64-linux`.
  This might be easily fixed
  by doing something more sophisticated in [`MODULE.bazel`](MODULE.bazel)
  than hard-wiring the platform.
  Pre-built binaries generally exist for MacOS as well.
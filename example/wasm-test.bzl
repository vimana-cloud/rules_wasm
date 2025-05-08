load("@bazel_skylib//rules:native_binary.bzl", "native_test")

def wasm_test(name, component):
    """
    A simple way to run a component implementing `wasi:cli/run` as a test using wasmtime.
    The test fails if `run` returns an error.
    """
    native_test(
        name = name,
        size = "small",
        src = Label("@rules_wasm//:wasmtime"),
        args = [
            "run",
            # Turn off caching because it doesn't play nice with Bazel on GitHub Actions.
            # Note that wasmtime insists that the flags precede the component path.
            "--codegen",
            "cache=n",
            "$(location {})".format(component),
        ],
        data = [component],
    )

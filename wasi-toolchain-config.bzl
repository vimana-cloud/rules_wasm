load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "tool_path")

def _wasi_toolchain_config_impl(ctx):
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "wasm32-wasip2",
        target_system_name = "wasm32-wasip2",
        target_cpu = "wasm32",
        target_libc = "wasip2",
        compiler = "clang",
        tool_paths = [
            tool_path(
                name = "gcc",
                path = "@wasi-sdk//:wasm32-wasip2-clang",
            ),
            tool_path(
                name = "cpp",
                path = "@wasi-sdk//:wasm32-wasip2-clang++",
            ),
            tool_path(
                name = "ld",
                path = "@wasi-sdk//:wasm-component-ld",
            ),
            tool_path(
                name = "ar",
                path = "@wasi-sdk//:ar",
            ),
            tool_path(
                name = "nm",
                path = "@wasi-sdk//:nm",
            ),
            tool_path(
                name = "objdump",
                path = "@wasi-sdk//:objdump",
            ),
            tool_path(
                name = "strip",
                path = "@wasi-sdk//:strip",
            ),
        ],
        cxx_builtin_include_directories = [
            "@wasi-sdk//lib/clang/18/include",
        ],
    )

wasi_toolchain_config = rule(
    implementation = _wasi_toolchain_config_impl,
    attrs = {},
    provides = [CcToolchainConfigInfo],
)
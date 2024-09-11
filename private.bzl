load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl", "tool_path")

# TODO: Figure out how to dedupe this list with `private.bzl`.
execution_platforms = [
    "aarch64-linux",
    "aarch64-macos",
    "x86_64-linux",
    "x86_64-macos",
]

def format_platform(template):
    """ Format a template string with the current execution platform. """
    return select(
        {
            "//:exe-" + platform: template.format(platform)
            for platform in execution_platforms
        },
        no_match_error = "Only (Linux | MacOS) & (Arm64 | x86-64) currently supported",
    )

def _wasi_toolchain_config_impl(ctx):
    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "wasm32-wasi",
        target_system_name = "wasm32-wasi",
        target_cpu = "wasm32",
        target_libc = "wasi",
        compiler = "clang",
        tool_paths = [
            tool_path(name = "gcc", path = "ignored"),
            tool_path(name = "cpp", path = "ignored"),
            tool_path(name = "ld", path = "ignored"),
            tool_path(name = "ar", path = "ignored"),
            tool_path(name = "nm", path = "ignored"),
            tool_path(name = "objdump", path = "ignored"),
            tool_path(name = "strip", path = "ignored"),
        ],
    )

wasi_toolchain_config = rule(
    implementation = _wasi_toolchain_config_impl,
    attrs = {},
    provides = [CcToolchainConfigInfo],
)

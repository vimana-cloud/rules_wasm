# Rust-specific rules and macros.

load("@rules_rust//rust:defs.bzl", "rust_library", "rust_shared_library")
load(":component.bzl", "wasm_component")
load(":private.bzl", "group_wit_files")

def _kebab_to_snake(s):
    "Convert a string from kebab-case to snake_case."
    return s.replace("-", "_")

def _rust_wit_bindgen_impl(ctx):
    world = ctx.attr.world or ctx.label.name
    wit_dir = group_wit_files(ctx, ctx.files.srcs, ctx.files.deps)
    output = ctx.actions.declare_file(_kebab_to_snake(world) + ".rs")
    outputs = [output]
    arguments = ["rust", "--world", world, "--out-dir", output.dirname, wit_dir.path]
    ctx.actions.run(
        inputs = [wit_dir],
        outputs = outputs,
        executable = ctx.executable._wit_bindgen_bin,
        arguments = arguments,
    )
    return [DefaultInfo(files = depset(outputs))]

rust_wit_bindgen = rule(
    implementation = _rust_wit_bindgen_impl,
    doc = "Generate Rust bindings from a WebAssembly Interface (WIT) file.",
    attrs = {
        "srcs": attr.label_list(
            doc = "Wasm interface (WIT) source files.",
            allow_files = [".wit"],
        ),
        "deps": attr.label_list(
            doc = "Wasm interface (WIT) dependencies; all files included by WIT sources.",
            allow_files = [".wit"],
        ),
        "world": attr.string(
            doc = "World to generate bindings for. Default is the target name.",
        ),
        "_wit_bindgen_bin": attr.label(
            # TODO: Use wit-bindgen-cli crate dependency
            #   instead of checking in the binary.
            # https://github.com/bazelbuild/rules_rust/discussions/2786
            default = "@wit-bindgen//:wit-bindgen",
            #default = "@wit-bindgen-release//:wit-bindgen",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
    },
)

def rust_component(name, srcs, wits, world = None, deps = None, wit_deps = None):
    """
    Compile a Wasm component given a set of interface definitions (`wits`),
    a set of Rust source files (`srcs`), and a world name.

    The default for `world` is `name`.
    """
    if world == None:
        world = name
    if deps == None:
        deps = []
    if wit_deps == None:
        wit_deps = []

    wit_name = name + " wit"
    rust_wit_bindgen(
        name = wit_name,
        srcs = wits,
        deps = wit_deps,
        world = world,
    )

    lib_name = name + " lib"
    rust_library(
        name = lib_name,
        srcs = [":" + wit_name],
        deps = ["@crates//:wit-bindgen"],
        crate_name = _kebab_to_snake(world),
    )

    core_name = name + " core"
    rust_shared_library(
        name = core_name,
        srcs = srcs,
        crate_name = _kebab_to_snake(world),
        deps = deps + [
            ":" + lib_name,
            "//:wit-bindgen-cabi-realloc",
        ],
        platform = "@rules_rust//rust/platform:wasi",
    )

    wasm_component(
        name = name,
        module = ":" + core_name,
        wits = wits,
        wit_deps = wit_deps,
    )

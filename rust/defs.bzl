# Rust-specific rules and macros.

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_rust//rust:defs.bzl", "rust_library", "rust_shared_library")
load("//:private.bzl", "intermediate_target_name", "kebab_to_snake")
load("//wasm:defs.bzl", "WitPackageInfo", "wasm_component")

def _rust_wit_bindgen_impl(ctx):
    world = ctx.attr.world or ctx.label.name
    snake_world = kebab_to_snake(world)

    # Put everything in a folder with the same name as the target to avoid name conflicts.
    # Generate the actual bindings in a subdirectory called `wit`.
    bindings = ctx.actions.declare_directory(paths.join(ctx.label.name, "wit"))
    ctx.actions.run(
        inputs = [ctx.attr.src[WitPackageInfo].info.directory],
        outputs = [bindings],
        executable = ctx.executable._wit_bindgen_bin,
        arguments = [
            "rust",
            ctx.attr.src[WitPackageInfo].info.directory.path,
            "--world",
            world,
            "--out-dir",
            bindings.path,
            "--generate-all",
            # Generate a public `export!` macro.
            "--pub-export-macro",
            # Make sure the generated `export!` macro uses the right namespace.
            "--default-bindings-module",
            snake_world,
        ],
    )

    # The wrapper `lib.rs` just republishes everything for the generated world.
    wrapper = ctx.actions.declare_file("lib.rs", sibling = bindings)
    ctx.actions.write(
        output = wrapper,
        content = """
mod wit {{
    pub mod {world};
}}

pub use wit::{world}::*;
""".format(world = snake_world),
    )

    return [DefaultInfo(files = depset([bindings, wrapper]))]

rust_wit_bindgen = rule(
    implementation = _rust_wit_bindgen_impl,
    doc = "Generate Rust bindings from a WebAssembly Interface (WIT).",
    attrs = {
        "src": attr.label(
            doc = "WIT package.",
            providers = [WitPackageInfo],
            mandatory = True,
        ),
        "world": attr.string(
            doc = "World to generate bindings for. Default is the target name.",
        ),
        "_wit_bindgen_bin": attr.label(
            default = "//:wit-bindgen",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)

def rust_component(name, srcs, wit, world = None, deps = None):
    """
    Compile a Wasm component given a WIT package (`wit`),
    a set of Rust source files (`srcs`), and a world name.

    The default for `world` is `name`.
    """
    if world == None:
        world = name
    snake_world = kebab_to_snake(world)
    if deps == None:
        deps = []

    wit_name = intermediate_target_name(name, "wit")
    rust_wit_bindgen(
        name = wit_name,
        src = wit,
        world = world,
    )

    lib_name = intermediate_target_name(name, "lib")
    rust_library(
        name = lib_name,
        srcs = [":" + wit_name],
        deps = [Label("@rules-wasm-crates//:wit-bindgen")],
        crate_name = snake_world,
    )

    core_name = intermediate_target_name(name, "core")
    rust_shared_library(
        name = core_name,
        srcs = srcs,
        crate_name = snake_world,
        deps = deps + [
            ":" + lib_name,
            Label("//:wit-bindgen-cabi"),
        ],
        platform = Label("@rules_rust//rust/platform:wasi"),
        # Make components as small as possible.
        rustc_flags = ["-C", "opt-level=s"],
    )

    wasm_component(
        name = name,
        module = ":" + core_name,
        wit = wit,
        world = world,
    )

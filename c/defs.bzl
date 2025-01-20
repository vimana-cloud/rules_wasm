# C-specific rules and macros.

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:defs.bzl", "cc_library")
load("//:platform-library.bzl", "platform_library")
load("//:private.bzl", "intermediate_target_name", "kebab_to_snake")
load("//wasm:defs.bzl", "WitPackageInfo", "wasm_component")

def _c_wit_bindgen_impl(ctx):
    world = ctx.attr.world or ctx.label.name
    snake_world = kebab_to_snake(world)

    # Output 3 files in a new directory named after the target label's name.
    # wit-bindgen hardcodes `#include` directives using the label's package,
    # so mirror that structure within the output directory.
    out_dir = paths.normalize(paths.join(ctx.label.name, ctx.label.package))
    source = ctx.actions.declare_file(paths.join(out_dir, snake_world + ".c"))
    header = ctx.actions.declare_file(snake_world + ".h", sibling = source)
    type_object = ctx.actions.declare_file(snake_world + "_component_type.o", sibling = source)
    outputs = [source, header, type_object]

    wit_bindgen_arguments = [
        "c",
        ctx.attr.src[WitPackageInfo].info.directory.path,
        "--world",
        world,
        "--out-dir",
        source.dirname,
    ]
    ctx.actions.run(
        inputs = [ctx.attr.src[WitPackageInfo].info.directory],
        outputs = outputs,
        executable = ctx.executable._wit_bindgen_bin,
        arguments = wit_bindgen_arguments,
    )

    # This is `out_dir` minus the label's package,
    # which is where clang can search for the generated header.
    include_directory = header.dirname.removesuffix(out_dir) + ctx.label.name

    return [
        DefaultInfo(files = depset(outputs)),
        CcInfo(
            compilation_context = cc_common.create_compilation_context(
                includes = depset([include_directory]),
            ),
        ),
    ]

c_wit_bindgen = rule(
    implementation = _c_wit_bindgen_impl,
    doc = "Generate C bindings from a WebAssembly Interface (WIT).",
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

def c_component(name, srcs, wit, world = None, deps = None):
    """
    Compile a Wasm component given a WIT package (`wit`),
    a set of C source files (`srcs`), and a world name.

    The default for `world` is `name`.
    """
    if world == None:
        world = name
    snake_world = kebab_to_snake(world)
    if deps == None:
        deps = []

    wit_name = intermediate_target_name(name, "wit")
    c_wit_bindgen(
        name = wit_name,
        src = wit,
        world = world,
    )

    # Building this target directly would result in a native (non-Wasm) library.
    native_name = intermediate_target_name(name, "native")
    cc_library(
        name = native_name,
        srcs = srcs + [":" + wit_name],
        deps = [":" + wit_name],
    )

    # Use a static platform transition to ensure that the WASI SDK is used
    # to compile a core Wasm module.
    core_name = intermediate_target_name(name, "core")
    platform_library(
        name = core_name,
        target = ":" + native_name,
        platform = Label("//:wasm32-wasi-platform"),
        extension = ".wasm",
    )

    wasm_component(
        name = name,
        module = ":" + core_name,
        wit = wit,
        world = world,
    )

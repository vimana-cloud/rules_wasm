# C-specific rules and macros.

load(":private.bzl", "intermediate_target_name", "kebab_to_snake")
load(":wasm.bzl", "wasm_component")

def _c_wit_bindgen_impl(ctx):
    world = ctx.attr.world or ctx.label.name
    snake_world = kebab_to_snake(world)

    # Output 3 files in a new directory named after the target label's name.
    if ctx.label.package == "":
        out_dir = "{}".format(ctx.label.name)
    else:
        # wit-bindgen hardcodes `#include` directives using the label's package,
        # so if that's non-empty, we need to mirror that structure in the output directory.
        out_dir = "{}/{}".format(ctx.label.name, ctx.label.package)
    source = ctx.actions.declare_file("{}/{}.c".format(out_dir, snake_world))
    header = ctx.actions.declare_file("{}.h".format(snake_world), sibling = source)
    type_object = ctx.actions.declare_file("{}_component_type.o".format(snake_world), sibling = source)
    all_outputs = [source, header, type_object]

    wit_bindgen_arguments = [
        "c",
        ctx.file.src.path,
        "--world",
        world,
        "--out-dir",
        source.dirname,
    ]
    ctx.actions.run(
        inputs = [ctx.file.src],
        outputs = all_outputs,
        executable = ctx.executable._wit_bindgen_bin,
        arguments = wit_bindgen_arguments,
    )

    return [DefaultInfo(files = depset(all_outputs))]

c_wit_bindgen = rule(
    implementation = _c_wit_bindgen_impl,
    doc = "Generate C bindings from a WebAssembly Interface (WIT).",
    attrs = {
        "src": attr.label(
            doc = "WIT source file or package.",
            allow_single_file = [".wit"],
        ),
        "world": attr.string(
            doc = "World to generate bindings for. Default is the target name.",
        ),
        "_wit_bindgen_bin": attr.label(
            default = "//:wit-bindgen",
            allow_files = True,
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

    # Use `clang` from the WASI SDK to compile the core module.
    core_name = intermediate_target_name(name, "core")
    native.cc_library(
        name = core_name,
        srcs = srcs + [":" + wit_name],
        hdrs = [":" + wit_name],
        #deps = [],
    )

    wasm_component(
        name = name,
        module = ":" + core_name,
        wit = wit,
        world = world,
    )

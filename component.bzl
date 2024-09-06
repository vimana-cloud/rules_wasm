# Language-agnostic rules and macros.

load(":private.bzl", "group_wit_files")

def _wasm_component_impl(ctx):
    wit_dir = group_wit_files(ctx, ctx.files.wits, ctx.files.wit_deps)
    output = ctx.actions.declare_file(ctx.label.name + ".component.wasm")
    outputs = [output]
    arguments = ["component", "embed", wit_dir.path, ctx.file.module.path, "-o", output.path]
    ctx.actions.run(
        inputs = [wit_dir, ctx.file.module],
        outputs = outputs,
        executable = ctx.executable._wasm_tools_bin,
        arguments = arguments,
    )
    return [DefaultInfo(files = depset(outputs))]

wasm_component = rule(
    implementation = _wasm_component_impl,
    doc = "Embed a Wasm Interface into a core module to create a component.",
    attrs = {
        "module": attr.label(
            doc = "Core Wasm module to embed the interface in.",
            allow_single_file = True,
        ),
        "wits": attr.label_list(
            doc = "Wasm interface (WIT) source files.",
            allow_files = [".wit"],
        ),
        "wit_deps": attr.label_list(
            doc = "Wasm interface (WIT) dependencies; all files included by WIT sources.",
            allow_files = [".wit"],
        ),
        "_wasm_tools_bin": attr.label(
            default = "@wasm-tools//:wasm-tools",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
    },
)

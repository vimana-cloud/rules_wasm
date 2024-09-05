# Language-agnostic rules and macros.

def _wasm_component_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".component.wasm")
    outputs = [output]
    arguments = ["component", "embed", ctx.file.wit.path, ctx.file.module.path, "-o", output.path]
    ctx.actions.run(
        inputs = [ctx.file.wit, ctx.file.module],
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
        "wit": attr.label(
            doc = "Wasm interface (WIT).",
            allow_single_file = True,
        ),
        "_wasm_tools_bin": attr.label(
            default = "@wasm-tools//:wasm-tools",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
    },
)
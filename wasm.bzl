# Language-agnostic rules and macros.

# Mapping from WASI packages to dependencies:
wasi_packages = {
    "cli": [
        "clocks",
        "filesystem",
        "io",
        "random",
        "sockets",
    ],
    "clocks": ["io"],
    "filesystem": [
        "clocks",
        "io",
    ],
    "http": [
        "cli",
        "clocks",
        "filesystem",
        "io",
        "random",
        "sockets",
    ],
    "io": [],
    "random": [],
    "sockets": [
        "clocks",
        "io",
    ],
}

WitPackageInfo = provider(
    "Information about a WIT package.",
    fields = {
        "name": "Short name of the package. Required.",
        "namespace": "Namespace of the package. Optional.",
        "version": "Version of the package. Optional.",
    },
)

def _bash_quote(path):
    """
    Surround a string with single-quotes.
    If it contains a single-quote, it is escaped a-la-Bash.
    """
    return "'{}'".format(path.replace("'", "'\"'\"'"))

def _wit_package_impl(ctx):
    package_name = ctx.attr.package_name or ctx.label.name
    package_dir = ctx.actions.declare_directory(package_name)
    deps_path = package_dir.path + "/deps"

    # Chain a bunch of Bash commands together with `&&`.
    commands = [
        # Start by hard-linking the source files into the output directory.
        "ln {srcs} {dir}".format(
            srcs = " ".join([_bash_quote(src.path) for src in ctx.files.srcs]),
            dir = _bash_quote(package_dir.path),
        ),
        # Create the `deps/` subfolder.
        # It will be empty if there are no dependencies.
        "mkdir {deps_dir}".format(deps_dir = _bash_quote(deps_path)),
    ]
    for dep in ctx.files.deps:
        if dep.is_directory:
            # Packaged dependencies need to have further subfolders created.
            dep_path = deps_path + "/" + dep.basename
            commands.append("mkdir {dep_dir}".format(dep_dir = _bash_quote(dep_path)))

            # Then their source files are hard-linked into that sub-subfolder.
            commands.append(
                "ln {dep_wits} {dep_dir}".format(
                    dep_wits = _bash_quote(dep.path) + "/*.wit",
                    dep_dir = _bash_quote(dep_path),
                ),
            )
        else:
            # Standalone dependency files can be hard-linked directly under `deps/`.
            commands.append(
                "ln {dep} {deps_dir}".format(
                    dep = _bash_quote(dep.path),
                    deps_dir = _bash_quote(deps_path),
                ),
            )

    ctx.actions.run_shell(
        inputs = ctx.files.srcs + ctx.files.deps,
        outputs = [package_dir],
        command = " && ".join(commands),
    )
    return [
        DefaultInfo(files = depset([package_dir])),
        # TODO: Do something about namespace and version (parse the files?).
        WitPackageInfo(name = package_name, namespace = None, version = None),
    ]

wit_package = rule(
    implementation = _wit_package_impl,
    doc =
        "Bundle a group of WIT files, belonging to the same package, into a unified dependency." +
        " Otherwise, only single-file packages can be depended upon.",
    attrs = {
        "srcs": attr.label_list(
            doc = "WIT source files.",
            allow_files = [".wit"],
        ),
        "deps": attr.label_list(
            doc = "WIT dependencies.",
            allow_files = [".wit"],
            providers = [WitPackageInfo],
        ),
        "package_name": attr.string(
            doc = "Explicit name for the package. Default is the build rule name.",
        ),
    },
)

def _wasm_component_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".component.wasm")
    outputs = [output]
    arguments = [
        "component",
        "embed",
        ctx.file.wit.path,
        ctx.file.module.path,
        "--world",
        ctx.attr.world or ctx.label.name,
        "--output",
        output.path,
    ]
    ctx.actions.run(
        inputs = [ctx.file.module, ctx.file.wit],
        outputs = outputs,
        executable = ctx.executable._wasm_tools_bin,
        arguments = arguments,
    )
    return [DefaultInfo(files = depset(outputs))]

wasm_component = rule(
    implementation = _wasm_component_impl,
    doc = "Embed a Wasm interface into a core module to create a component.",
    attrs = {
        "module": attr.label(
            doc = "Core Wasm module to embed the interface in.",
            allow_single_file = [".wasm", ".wat"],
        ),
        "wit": attr.label(
            doc = "WIT source package.",
            allow_single_file = [".wit"],
            providers = [WitPackageInfo],
        ),
        "world": attr.string(
            doc = "World to generate bindings for. Default is the target name.",
        ),
        "_wasm_tools_bin": attr.label(
            default = "@wasm-tools//:wasm-tools",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
    },
)

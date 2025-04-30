# Language-agnostic rules and macros.

# TODO: Figure out how to dedupe this with `wasi.patch`.
# Mapping from WASI packages to direct dependencies:
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
        "io",
        "random",
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
        "directory": "Generated WIT package directory.",
        "deps": "Direct and transitive dependency set.",
    },
)

def _wit_package_impl(ctx):
    # The output of this action is a single directory, named after the build rule name:
    #
    #     <name>
    #     ├── [source files ...]
    #     └── deps/
    #         ├── <dependency-1>/
    #         │   └── [dependency-1 source files ...]
    #         ├── <dependency-2>/
    #         │   └── [dependency-2 source files ...]
    #         └── ...
    #
    # Each dependency's name is the unique full, versioned package name declared in that package,
    # or the original filename if none (or multiple) are declared.
    #
    # This is due to under-documented implementation details of wit-bindgen:
    # https://github.com/bytecodealliance/wit-bindgen/issues/1046.

    package_dir = ctx.actions.declare_directory(ctx.label.name)
    deps = depset(
        ctx.files.deps,
        transitive = [dep[WitPackageInfo].deps for dep in ctx.attr.deps],
    )
    all_deps = deps.to_list()

    ctx.actions.run(
        inputs = ctx.files.srcs + all_deps,
        outputs = [package_dir],
        executable = ctx.executable._wit_package_bin,
        arguments = [
            package_dir.path,
            str(len(ctx.files.srcs)),
        ] + [src.path for src in ctx.files.srcs] + [
            str(len(all_deps)),
        ] + [dep.path for dep in all_deps],
    )

    return [
        DefaultInfo(files = depset([package_dir])),
        WitPackageInfo(directory = package_dir, deps = deps),
    ]

wit_package = rule(
    implementation = _wit_package_impl,
    doc =
        "Bundle a group of WIT files belonging to the same package, along with dependencies.",
    attrs = {
        "srcs": attr.label_list(
            doc = "WIT source files.",
            allow_files = [".wit"],
        ),
        "deps": attr.label_list(
            doc = "WIT package dependencies.",
            providers = [WitPackageInfo],
        ),
        "_wit_package_bin": attr.label(
            default = "//:wit-package",
            executable = True,
            cfg = "exec",
        ),
    },
    provides = [WitPackageInfo],
)

_component_suffix = ".component.wasm"

def _wasm_component_impl(ctx):
    embedded = ctx.actions.declare_file(ctx.label.name + ".embedded.wasm")
    ctx.actions.run(
        inputs = [ctx.file.module, ctx.file.wit],
        outputs = [embedded],
        executable = ctx.executable._wasm_tools_bin,
        arguments = [
            "component",
            "embed",
            ctx.file.wit.path,
            ctx.file.module.path,
            "--world",
            ctx.attr.world or ctx.label.name,
            "--output",
            embedded.path,
        ],
    )
    component = ctx.actions.declare_file(ctx.label.name + _component_suffix)
    ctx.actions.run(
        inputs = [embedded, ctx.file._adapter],
        outputs = [component],
        executable = ctx.executable._wasm_tools_bin,
        arguments = [
            "component",
            "new",
            embedded.path,
            "--adapt",
            ctx.file._adapter.path,
            "--output",
            component.path,
        ],
    )
    return [DefaultInfo(files = depset([component]))]

wasm_component = rule(
    implementation = _wasm_component_impl,
    doc = "Embed a Wasm interface into a core module and create a component.",
    attrs = {
        "module": attr.label(
            doc = "Core Wasm module to embed the interface in.",
            allow_single_file = [".wasm", ".wat"],
        ),
        "wit": attr.label(
            doc = "WIT package where the interface world is defined.",
            allow_single_file = [".wit"],
            providers = [WitPackageInfo],
        ),
        "world": attr.string(
            doc = "World for the component, which must be defined in the WIT package." +
                  " Use the target name if unspecified.",
        ),
        "_wasm_tools_bin": attr.label(
            default = "//:wasm-tools",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_adapter": attr.label(
            default = "//:wasi-snapshot-preview1-reactor",
            allow_single_file = True,
        ),
    },
)

def _wasm_plug_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + _component_suffix)
    ctx.actions.run(
        inputs = [ctx.file.wrapper, ctx.file.plug],
        outputs = [output],
        executable = ctx.executable._wac_bin,
        arguments = [
            "plug",
            ctx.file.wrapper.path,
            "--plug",
            ctx.file.plug.path,
            "--output",
            output.path,
        ],
    )
    return [DefaultInfo(files = depset([output]))]

wasm_plug = rule(
    implementation = _wasm_plug_impl,
    doc = "Compose simple Wasm compositions without a WAC file.",
    attrs = {
        "wrapper": attr.label(
            doc = "Wrapper component to plug into.",
            allow_single_file = [".wasm", ".wat"],
        ),
        "plug": attr.label(
            doc = "Plug component to be wrapped around.",
            allow_single_file = [".wasm", ".wat"],
        ),
        "_wac_bin": attr.label(
            default = "//:wac",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
)

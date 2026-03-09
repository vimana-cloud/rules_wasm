# Go-specific rules and macros.

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@io_bazel_rules_go//go:def.bzl", "go_context")
load("@io_bazel_rules_go//go/private:providers.bzl", "GoArchive", "GoInfo")
load("@rules_license//rules:providers.bzl", "PackageInfo")
load("//:private.bzl", "intermediate_target_name")
load("//wasm:defs.bzl", "WitPackageInfo", "component_suffix")

GO_TOOLCHAIN_TYPE = "@io_bazel_rules_go//go:toolchain"
JQ_TOOLCHAIN_TYPE = "@jq.bzl//jq/toolchain:type"

GoWitBindgenInfo = provider(
    "Information relevant to generated Go WIT bindings.",
    fields = {
        "bindings": "Generated WIT bindings directory as a single File object.",
        "wit": "Original WIT package directory as a single File object.",
        "module_name": "Go import path prefix for the generated bindings.",
    },
)

def _go_wit_bindgen_impl(ctx):
    world = ctx.attr.world or ctx.label.name
    wit_info = ctx.attr.src[WitPackageInfo].info
    package_path = _wit_package_to_path(wit_info.package)
    package_root = paths.join(package_path, _kebab_to_go_package(world))

    # Put everything in a folder with the same name as the target to avoid name conflicts.
    output = ctx.actions.declare_directory(ctx.label.name)
    ctx.actions.run(
        inputs = [wit_info.directory],
        outputs = [output],
        executable = ctx.executable._wit_bindgen_go_runner_bin,
        arguments = [
            ctx.executable._wit_bindgen_go_bin.path,
            wit_info.directory.path,
            world,
            ctx.attr.module,
            package_root,
            output.path,
        ],
        tools = [
            ctx.executable._wit_bindgen_go_bin,
        ],
    )

    return [
        DefaultInfo(files = depset([output])),
        GoWitBindgenInfo(
            bindings = output,
            wit = wit_info.directory,
            module_name = ctx.attr.module,
        ),
    ]

go_wit_bindgen = rule(
    implementation = _go_wit_bindgen_impl,
    doc = "Generate Go bindings from a WebAssembly Interface (WIT).",
    attrs = {
        "src": attr.label(
            doc = "WIT package.",
            providers = [WitPackageInfo],
            mandatory = True,
        ),
        "world": attr.string(
            doc = "World to generate bindings for. Default is the target name.",
        ),
        "module": attr.string(
            doc = "Go import path prefix for the generated bindings.",
            mandatory = True,
        ),
        "_wit_bindgen_go_bin": attr.label(
            default = ":wit-bindgen-go",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_wit_bindgen_go_runner_bin": attr.label(
            default = ":wit-bindgen-go-runner",
            executable = True,
            cfg = "exec",
        ),
    },
)

def _package_directory(srcs, package_name):
    """
    Return the relative path to the common direct parent of a list of source files.
    Fail if the files do not share a single common direct parent.
    """
    package_paths = set([paths.dirname(src.path) for src in srcs])
    if len(package_paths) == 0:
        fail("No source files in {}".format(package_name))
    if len(package_paths) > 1:
        fail("All source files for {} must be in the same directory".format(package_name))
    # Use a relative path to indicate that this is not a system package.
    return "./{}".format(package_paths.pop())

def _go_module_impl(ctx):
    world = ctx.attr.world or ctx.label.name
    bindgen_info = ctx.attr.wit[GoWitBindgenInfo]
    cm_go_mod = ctx.file._cm_go_mod
    cm_library = ctx.attr._cm_library[GoInfo]
    cm_package_info = ctx.attr._cm_package_info[PackageInfo]

    main_package_path = _package_directory(ctx.files.srcs, "main package")

    inputs = [bindgen_info.bindings, bindgen_info.wit, cm_go_mod]
    inputs.extend(ctx.files.srcs)
    inputs.extend(cm_library.srcs)

    dep_arguments = []
    all_importpaths = set()
    for dep in ctx.attr.deps:
        for archive_data in dep[GoArchive].transitive.to_list():
            importpath = archive_data.importpath
            if importpath in all_importpaths:
                continue
            all_importpaths.add(importpath)

            package_srcs = list(archive_data.srcs)
            inputs.extend(package_srcs)
            inputs.extend(list(archive_data._embedsrcs))
            package_path = _package_directory(package_srcs, "package '{}'".format(importpath))
            dep_arguments += [importpath, package_path]

    jq_toolchain = ctx.toolchains[JQ_TOOLCHAIN_TYPE]
    go_bin = go_context(ctx).sdk.go

    output = ctx.actions.declare_file(ctx.label.name + component_suffix)
    ctx.actions.run(
        executable = ctx.executable._tinygo_runner_bin,
        inputs = inputs,
        outputs = [output],
        arguments = [
            ctx.executable._tinygo_bin.path,
            go_bin.path,
            ctx.executable._wasm_tools_bin.path,
            ctx.executable._wasm_opt_bin.path,
            jq_toolchain.jqinfo.bin.path,
            output.path,
            bindgen_info.bindings.path,
            bindgen_info.wit.path,
            bindgen_info.module_name,
            paths.dirname(cm_go_mod.path),
            cm_package_info.package_name,
            cm_package_info.package_version,
            world,
            main_package_path,
        ] + dep_arguments,
        tools = [
            ctx.executable._tinygo_bin,
            ctx.executable._wasm_opt_bin,
            ctx.executable._wasm_tools_bin,
            go_bin,
        ],
    )

    return [DefaultInfo(files = depset([output]))]

# Stopgap solution while figuring out how to compile the output of `wit-bindgen-go` using `rules_go`.
# https://github.com/bazel-contrib/rules_go/issues/4333
go_module = rule(
    implementation = _go_module_impl,
    doc = "Compile a Wasm core module from Go code and generated WIT bindings using tinygo.",
    attrs = {
        "srcs": attr.label_list(
            doc = "Go source files",
            allow_files = [".go"],
        ),
        "deps": attr.label_list(
            doc = "Go library dependencies",
            providers = [GoInfo],
        ),
        "wit": attr.label(
            doc = "Label of a `go_wit_bindgen` rule with relevant Go WIT bindings",
            providers = [GoWitBindgenInfo],
            mandatory = True,
        ),
        "world": attr.string(
            doc = "World to generate bindings for. Default is the target name.",
        ),
        "_cm_go_mod": attr.label(
            default = "@go-component-model-utility//:go.mod",
            allow_single_file = True,
        ),
        "_cm_library": attr.label(
            default = "@go-component-model-utility//:cm",
            providers = [GoInfo],
        ),
        "_cm_package_info": attr.label(
            default = "@go-component-model-utility//:package-info",
            providers = [PackageInfo],
        ),
        # https://github.com/bazel-contrib/rules_go/blob/v0.58.3/go/toolchains.rst#writing-new-go-rules
        "_go_context_data": attr.label(
            default = "@io_bazel_rules_go//:go_context_data",
        ),
        "_tinygo_bin": attr.label(
            default = ":tinygo",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_tinygo_runner_bin": attr.label(
            default = ":tinygo-runner",
            executable = True,
            cfg = "exec",
        ),
        "_wasm_opt_bin": attr.label(
            default = "//:wasm-opt",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_wasm_tools_bin": attr.label(
            default = "//:wasm-tools",
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = [
        GO_TOOLCHAIN_TYPE,
        JQ_TOOLCHAIN_TYPE,
    ],
)

def go_component(name, srcs, wit, wit_module, world = None, deps = None):
    """
    Compile a Wasm component given a WIT package (`wit`),
    a set of Go source files (`srcs`), and a world name.
    A Go module name for the generated WIT bindings (`wit_module`) is also required.

    The default for `world` is `name`.
    """
    if world == None:
        world = name
    if deps == None:
        deps = []

    wit_name = intermediate_target_name(name, "wit")
    go_wit_bindgen(
        name = wit_name,
        src = wit,
        world = world,
        module = wit_module,
    )

    go_module(
        name = name,
        srcs = srcs,
        wit = ":" + wit_name,
        world = world,
        deps = deps,
    )

def _wit_package_to_path(package):
    return paths.join(*package.split(":"))

def _kebab_to_go_package(name):
    return name.replace("-", "")

def _file_path_arguments(files):
    return " ".join(["'{}'".format(file.path) for file in files])

def group_wit_files(ctx, srcs, deps):
    """
    Given a Bazel rule implementation context (`ctx`), and a set of WIT `File` objects (`srcs`),
    create a new directory named "wit" containing hard-links to every source file,
    and return that directory's `File` object.

    If `deps` are provided, create a nested directory called "deps" containing those files.
    """
    wit_dir = ctx.actions.declare_directory("wit")
    command = "ln {srcs} {dir}".format(dir = wit_dir.path, srcs = _file_path_arguments(srcs))
    if len(deps) > 0:
        command += \
            "&& mkdir {deps_dir} && ln {deps} {deps_dir}" \
                .format(deps_dir = wit_dir.path + "/deps", deps = _file_path_arguments(deps))
    ctx.actions.run_shell(
        inputs = srcs + deps,
        outputs = [wit_dir],
        command = command,
    )
    return wit_dir

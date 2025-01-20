# Rules to build a binary for a Docker container,
# which typically requires a specific platform regardless of the host.
# Crazy that we need 50+ lines of Starlark just to set the platform.
#
# Inspired by
# https://github.com/bazelbuild/platforms/blob/0.0.11/experimental/platform_data/defs.bzl.
# TODO: Upstream?

_platform_option = "//command_line_option:platforms"

def _platform_library_transition_impl(settings, attr):
    return {_platform_option: str(attr.platform)}

_platform_library_transition = transition(
    implementation = _platform_library_transition_impl,
    inputs = [],
    outputs = [_platform_option],
)

def _platform_library_impl(ctx):
    print(ctx.attr.target)
    output = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.symlink(
        output = output,
        target_file = ctx.attr.target[0][DefaultInfo].files.to_list()[0],
    )
    return [DefaultInfo(files = depset([output]))]

platform_library = rule(
    implementation = _platform_library_impl,
    attrs = {
        "target": attr.label(
            doc = "The target to transition.",
            allow_single_file = False,
            mandatory = True,
            cfg = _platform_library_transition,
        ),
        "platform": attr.label(
            doc = "The platform to transition to.",
            mandatory = True,
        ),
    },
)

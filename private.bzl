# TODO: Figure out how to dedupe this list with `MODULE.bazel`.
execution_platforms = [
    "aarch64-linux",
    "aarch64-macos",
    "x86_64-linux",
    "x86_64-macos",
]

def format_platform(template):
    """ Format a template string with the current execution platform. """
    return select(
        {
            "//:exe-" + platform: template.format(platform)
            for platform in execution_platforms
        },
        no_match_error = "Only (Linux | MacOS) & (Arm64 | x86-64) currently supported",
    )

def kebab_to_snake(s):
    "Convert a string from kebab-case to snake_case."
    return s.replace("-", "_")

def intermediate_target_name(root, affix):
    """
    Macros generate intermediate targets for a "root" target based on various affixes.
    Format those intermediate target names so that they're decently readable
    while reducing the risk of collisions.
    """
    return "{}.{}".format(root, affix)

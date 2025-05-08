#!/usr/bin/env bash

# Compile a WIT package,
# consisting of a set of source files and an optional set of dependencies,
# into magical undocumented WIT dependency form:
# https://github.com/bytecodealliance/wit-bindgen/issues/1046.
#
# Try hardlinking WIT files first for performance.
# Fall back to a deep copy due to Apple "security".
#
# $1: Output directory.
# $2: Package name.
# $3: Number of WIT source files.
# $[4*]: WIT source files.
# $5: Number of WIT dependencies.
# $[6*]: WIT dependencies.

# Print the unique package name from a concatenated set of WIT source files.
# If there are no package declarations, or multiple distinct package names, return non-zero.
function get-package-name {
  # First eliminate all block comments from the input,
  # then search for valid `package` declaration lines and print the package name only.
  sed -En 's@/\*([^*]|\*[^/])*\*/@@g; s@^package[ \t]+([^ \t]+)[ \t]*;[ \t]*(//.*)?$@\1@p' \
    | uniq \
    | (
      if read full_package_name
      then
        # `full_package_name` includes all namespaces / names and optional version.

        if read conflicting_package_name
        then
          # When there are multiple declarations, print a message and return an error status,
          # which indicates to the caller to use some default.
          echo >&2 "Conflicting package declarations '$full_package_name' and '$conflicting_package_name'."
          return 1
        fi

        # When there is a single declaration, use it.
        echo "$full_package_name"
      else
        # No package declaration in package source.
        # Return an error status to indicate to the caller to use some default.
        return 1
      fi
    )
}

# Convert the arguments into an array so we can slice it.
args=("$@")

outdir="${args[0]}"
package="${args[1]}"
src_count="${args[2]}"
dep_count="${args[$(( src_count + 3 ))]}"

if (( src_count > 0 ))
then
  srcs="${args[@]:3:$src_count}"

  # Validate that all the source files are part of the declared package.
  cat ${srcs[@]} \
    | get-package-name \
    | if read actual_package
      then
        # Ignore the version (anything after `@` if there is one).
        actual_package="${actual_package%%@*}"

        if [[ "$package" != "$actual_package" ]]
        then
          echo >&2 "Declared package name '$package' does not match detected '$actual_package'."
          exit 1
        fi
      fi || exit $?  # Propagate any error from the piped subshell.

  # Try hardlinking first for performance.
  # Fallback to a deep copy due to Apple "security".
  ln ${srcs[@]} "$outdir" || cp ${srcs[@]} "$outdir"
fi

if (( dep_count > 0 ))
then
  deps="${args[@]:$((src_count + 4)):$dep_count}"
  # Make the special `/deps` subfolder and copy all the dependencies.
  deps_dir="$outdir/deps"
  mkdir "$deps_dir" && \
    for dep in ${deps[@]}
    do
      # Extract an explicit package name declaration
      # and use that as the destination file / directory name to avoid collisions.
      # Default to the input directory name.
      outname="$deps_dir/$(cat "$dep"/*.wit | get-package-name || basename "$dep")"
      mkdir "$outname" && ( ln "$dep"/*.wit "$outname" || cp "$dep"/*.wit "$outname" )
    done
fi

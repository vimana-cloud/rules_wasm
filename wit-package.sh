#!/bin/bash

# Compile a WIT package,
# consisting of a set of source files and an optional set of dependencies,
# into magical undocumented WIT dependency form:
# https://github.com/bytecodealliance/wit-bindgen/issues/1046.
#
# Try hardlinking WIT files first for performance.
# Fall back to a deep copy due to Apple "security".
#
# $1: Output directory.
# $2: Number of WIT source files.
# $[3*]: WIT source files.
# $4: Number of WIT dependencies.
# $[5*]: WIT dependencies.

# Print the package name from a single WIT package declaration in input.
# If there are no declarations, or multiple, return non-zero.
function get-package-name {
  sed -En 's/^package\s+([^ \t]+)\s*;\s*$/\1/p' | uniq | (
    if read full_package_name
    then
      # `full_package_name` includes all namespaces / names and optional version.

      if read conflicting_package_name
      then
        # When there are multiple declarations, print a message but use the default.
        echo >&2 "Conflicting package declarations: $full_package_name $conflicting_package_name"
        return 1
      fi

      # When there is a single declaration, use it.
      echo "$full_package_name"
    else
      # No package declaration in package source. Use the default.
      return 1
    fi
  )
}

# Convert the arguments into an array so we can slice it.
args=("$@")
outdir="${args[0]}"
src_count="${args[1]}"
dep_count="${args[$(( src_count + 2 ))]}"

if (( src_count > 0 ))
then
  srcs="${args[@]:2:$src_count}"
  # Try hardlinking first for performance.
  # Fallback to a deep copy due to Apple "security".
  ln ${srcs[@]} "$outdir" || cp ${srcs[@]} "$outdir"
fi

if (( dep_count > 0 ))
then
  deps="${args[@]:$((src_count + 3)):$dep_count}"
  # Make the special `/deps` subfolder and copy all the dependencies.
  deps_dir="$outdir/deps"
  mkdir "$deps_dir" && \
    for dep in ${deps[@]}
    do
      # Extract an explicit package name declaration
      # and use that as the destination file / directory name to avoid collisions.
      # Default to the input file / directory name.
      if [ -d "$dep" ]
      then
        outname="$deps_dir/$(cat "$dep"/*.wit | get-package-name || basename "$dep")"
        mkdir "$outname" && ( ln "$dep"/*.wit "$outname" || cp "$dep"/*.wit "$outname" )
      else
        outname="$deps_dir/$(get-package-name < "$dep" || basename "$dep" .wit).wit"
        ln "$dep" "$outname" || cp "$dep" "$outname"
      fi
    done
fi

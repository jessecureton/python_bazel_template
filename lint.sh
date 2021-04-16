#! /bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"

function print_error {
    read line file <<<$(caller)
    printf "\n⛔️ An error occurred during the following lint step ⛔️\n" >&2
    sed "${line}q;d" "$file" >&2
}
trap print_error ERR


#####################
# Bazel file linting
#####################
# Find all Bazel-ish files - these templates come from Buildifier's default search list
BAZEL_FILES=$(find ${REPO_ROOT} -type f \
            \(   -name "*.bzl" \
              -o -name "*.sky" \
              -o -name "BUILD.bazel" \
              -o -name "BUILD" \
              -o -name "*.BUILD" \
              -o -name "BUILD.*.bazel" \
              -o -name "BUILD.*.oss" \
              -o -name "WORKSPACE" \
              -o -name "WORKSPACE.bazel" \
              -o -name "WORKSPACE.oss" \
              -o -name "WORKSPACE.*.bazel" \
              -o -name "WORKSPACE.*.oss" \) \
              -print)
BUILDIFIER_ARGS=("-mode=fix" "-v=false")
BUILDIFIER_INVOCATION="bazel run -- //tools/buildifier ${BUILDIFIER_ARGS[@]}"
echo $BAZEL_FILES | xargs ${BUILDIFIER_INVOCATION}


#################
# Python linting
#################
# Sort imports
bazel run -- //tools/isort ${REPO_ROOT}
# Autoformat
bazel run -- //tools/black ${REPO_ROOT}
# Ensure flake8 compliance
bazel run -- //tools/flake8 ${REPO_ROOT}

printf "\n✨ Linting completed successfully! ✨\n"

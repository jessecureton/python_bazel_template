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
              -o -name "MODULE.bazel" \
              -o -name "WORKSPACE" \
              -o -name "WORKSPACE.bazel" \
              -o -name "WORKSPACE.oss" \
              -o -name "WORKSPACE.*.bazel" \
              -o -name "WORKSPACE.*.oss" \) \
              -print)
BUILDIFIER_ARGS=("-lint=fix" "-mode=fix" "-v=false")
BUILDIFIER_INVOCATION="bazel run -- //tools/buildifier ${BUILDIFIER_ARGS[@]}"
echo $BAZEL_FILES | xargs ${BUILDIFIER_INVOCATION}

#################
# Python linting
#################
# Sort imports
bazel run -- //tools/isort ${REPO_ROOT} --dont-follow-links
# Autoformat
bazel run -- //tools/black ${REPO_ROOT}
# Ensure flake8 compliance
bazel run -- //tools/flake8 ${REPO_ROOT}

#################
# Go linting
#################
GO_FILES=$(find ${REPO_ROOT} -type f -name "*.go" -print)
GOFMT_ARGS=("")
GOFMT_INVOCATION="bazel run -- @rules_go//go fmt ${GOFMT_ARGS[@]}"
echo $GO_FILES | xargs ${GOFMT_INVOCATION}

#################
# Markdown Linting
#################
MARKDOWN_FILES=$(find ${REPO_ROOT} -type f -name "*.md" -print)
PRETTIER_ARGS=("--write" "--config ${REPO_ROOT}/.prettierrc")
PRETTIER_INVOCATION="bazel run -- //tools/prettier ${PRETTIER_ARGS[@]}"
echo $MARKDOWN_FILES | xargs ${PRETTIER_INVOCATION}


printf "\n✨ Linting completed successfully! ✨\n"

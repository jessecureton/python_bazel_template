load("@bazel_gazelle//:def.bzl", "gazelle", "gazelle_binary")
load("@npm//:defs.bzl", "npm_link_all_packages")
load("@pip//:requirements.bzl", "all_whl_requirements")
load("@rules_go//go:def.bzl", "TOOLS_NOGO", "nogo")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")
load("@rules_python_gazelle_plugin//manifest:defs.bzl", "gazelle_python_manifest")
load("@rules_python_gazelle_plugin//modules_mapping:def.bzl", "modules_mapping")

# This rule fetches the metadata for python packages we depend on. That data is
# required for the gazelle_python_manifest rule to update our manifest file.
modules_mapping(
    name = "modules_map",
    wheels = all_whl_requirements,
)

# Gazelle python extension needs a manifest file mapping from
# an import to the installed package that provides it.
# This macro produces two targets:
# - //:gazelle_python_manifest.update can be used with `bazel run`
#   to recalculate the manifest
# - //:gazelle_python_manifest.test is a test target ensuring that
#   the manifest doesn't need to be updated
gazelle_python_manifest(
    name = "gazelle_python_manifest",
    modules_mapping = ":modules_map",
    # This is what we called our `pip_parse` rule, where third-party
    # python libraries are loaded in BUILD files.
    pip_repository_name = "pip",
    requirements = "//:requirements_lock.txt",
)

gazelle_binary(
    name = "gazelle_with_plugins",
    languages = [
        "@rules_python_gazelle_plugin//python",  # Use gazelle from rules_python.
        "@bazel_gazelle//language/go",  # Built-in rule from gazelle for Golang.
        "@bazel_gazelle//language/proto",  # Built-in rule from gazelle for Protos.
        # Any languages that depend on Gazelle's proto plugin must come after it.
    ],
)

# gazelle:map_kind go_binary ${project}_go_binary //tools/rules/golang:defs.bzl
# gazelle:map_kind go_library ${project}_go_library //tools/rules/golang:defs.bzl
# gazelle:map_kind go_test ${project}_go_test //tools/rules/golang:defs.bzl
# gazelle:map_kind py_binary ${project}_py_binary //tools/rules/python:defs.bzl
# gazelle:map_kind py_library ${project}_py_library //tools/rules/python:defs.bzl
# gazelle:map_kind py_test ${project}_py_test //tools/rules/python:defs.bzl
# gazelle:python_library_naming_convention $package_name$_mylib
# gazelle:python_binary_naming_convention $package_name$_mybin
# gazelle:python_test_naming_convention $package_name$_mytest
# gazelle:python_generation_mode package
gazelle(
    name = "gazelle",
    gazelle = ":gazelle_with_plugins",
)

nogo(
    name = "nogo",
    visibility = ["//visibility:public"],
    deps = TOOLS_NOGO,
)

# Set up our pip requirements
compile_pip_requirements(
    name = "requirements",
    #extra_args = ["--allow-unsafe"],
    requirements_in = "requirements.in",
    requirements_txt = "requirements_lock.txt",
)

npm_link_all_packages(name = "node_modules")

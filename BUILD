load("@gazelle//:def.bzl", "gazelle")
load("@rules_python//python:defs.bzl", "py_runtime_pair")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")
load("@rules_go//go:def.bzl", "TOOLS_NOGO", "nogo")
load("@npm//:defs.bzl", "npm_link_all_packages")

# gazelle:map_kind go_binary ${project}_go_binary //tools/rules/golang:defs.bzl
# gazelle:map_kind go_library ${project}_go_library //tools/rules/golang:defs.bzl
# gazelle:map_kind go_test ${project}_go_test //tools/rules/golang:defs.bzl
gazelle(name = "gazelle")

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

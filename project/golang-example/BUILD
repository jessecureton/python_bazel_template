load("//tools/rules/golang:defs.bzl", "${project}_go_binary", "${project}_go_library", "${project}_go_test")

${project}_go_library(
    name = "go_default_library",
    srcs = ["main.go"],
    importpath = "github.com/example/${project}/${project}/golang-example",
    visibility = ["//visibility:private"],
)

${project}_go_test(
    name = "go_default_test",
    srcs = ["main_test.go"],
    embed = [":go_default_library"],
    deps = ["@com_github_stretchr_testify//assert:go_default_library"],
)

${project}_go_binary(
    name = "golang-example",
    embed = [":go_default_library"],
    visibility = ["//visibility:public"],
)

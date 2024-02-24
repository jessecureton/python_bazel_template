load("//tools/rules/golang:defs.bzl", "${project}_go_binary", "${project}_go_library", "${project}_go_test")

${project}_go_library(
    name = "golang-example_lib",
    srcs = ["main.go"],
)

${project}_go_binary(
    name = "golang-example",
    embed = [":golang-example_lib"],
)

${project}_go_test(
    name = "golang-example_test",
    srcs = ["main_test.go"],
    embed = [":golang-example_lib"],
)

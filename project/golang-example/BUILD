load("@rules_go//go:def.bzl", "go_binary", "go_library", "go_test")

go_library(
    name = "golang-example_lib",
    srcs = ["main.go"],
)

go_binary(
    name = "golang-example",
    embed = [":golang-example_lib"],
)

go_test(
    name = "golang-example_test",
    srcs = ["main_test.go"],
    embed = [":golang-example_lib"],
)

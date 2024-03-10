load("//tools/rules/golang:defs.bzl", "${project}_go_binary", "${project}_go_image", "${project}_go_library", "${project}_go_test")

${project}_go_library(
    name = "golang-example_lib",
    srcs = ["main.go"],
    importpath = "github.com/example/${project}/golang-example",
    visibility = ["//visibility:private"],
)

${project}_go_binary(
    name = "golang-example",
    embed = [":golang-example_lib"],
    visibility = ["//visibility:public"],
)

${project}_go_test(
    name = "golang-example_test",
    srcs = ["main_test.go"],
    embed = [":golang-example_lib"],
    deps = ["@com_github_stretchr_testify//assert"],
)

# Build and run this image with
#     bazel run //${project}/golang-example:golang-example_img_load_docker
#     docker run --rm ${project}/golang-example:latest
${project}_go_image(
    name = "golang-example_img",
    binary = ":golang-example",
    image_tags = ["${project}/golang-example:latest"],
)

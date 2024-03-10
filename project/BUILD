load("//tools/rules/python:defs.bzl", "${project}_py_binary", "${project}_py_image", "${project}_py_test")

# gazelle:prefix github.com/example/${project}

${project}_py_binary(
    name = "${project}",
    srcs = glob([
        "*.py",
    ]),
    main = "main.py",
    visibility = ["//visibility:public"],
    deps = [],
)

${project}_py_test(
    name = "${project}_test",
    srcs = glob(["test/*_test.py"]),
    deps = [
        ":${project}",
    ],
)

# Build and run this image with
#     bazel run //${project}:${project}_img_load_docker
#     docker run --rm ${project}:latest
${project}_py_image(
    name = "${project}_img",
    binary = ":${project}",
    image_tags = ["${project}:latest"],
)

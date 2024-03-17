load("//tools/rules/python:defs.bzl", "${project}_py_binary", "${project}_py_image", "${project}_py_test")

# Set the prefix for Golang packages to be here
# gazelle:prefix github.com/example/${project}

# Tell gazelle that are python root is the same dir as this Bazel package.
# (It's unclear to me if this is actually required or even appropriate, but
#  it definitely works and it seems best to /not/ have //tools in the python path)
# gazelle:python_root
# gazelle:resolve py ${project} //${project}

${project}_py_binary(
    name = "${project}",
    srcs = glob([
        "*.py",
    ]),
    main = "main.py",
    visibility = ["//visibility:public"],
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

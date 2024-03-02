load("@pip//:requirements.bzl", "requirement")
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

#${project}_py_image(
#    name = "${project}_img",
#    binary = ":${project}",
#    visibility = ["//visibility:public"],
#)

${project}_py_test(
    name = "${project}_test",
    srcs = glob(["test/*_test.py"]),
    deps = [
        ":${project}",
    ],
)

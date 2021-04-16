load("@pip//:requirements.bzl", "requirement")
load("//tools/rules/python:defs.bzl", "${project}_py_binary")

${project}_py_binary(
    name = "black",
    srcs = ["main.py"],
    main = "main.py",
    deps = [
        requirement("black"),
    ],
)

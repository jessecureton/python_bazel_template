load("@pip//:requirements.bzl", "requirement")
load("//tools/rules/python:defs.bzl", "${project}_py_library")

${project}_py_library(
    name = "test_runner",
    srcs = ["test_runner.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("pytest"),
    ],
)

load("@pip//:requirements.bzl", "requirement")
load("//tools/rules/python:defs.bzl", "${project}_py_binary")

${project}_py_binary(
    name = "${project}",
    srcs = ["main.py"],
    main = "main.py",
    visibility = ["//visibility:public"],
)

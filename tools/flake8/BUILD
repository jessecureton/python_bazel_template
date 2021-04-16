load("@pip//:requirements.bzl", "requirement")
load("//tools/rules/python:defs.bzl", "${project}_py_binary")

${project}_py_binary(
    name = "flake8",
    srcs = ["main.py"],
    main = "main.py",
    deps = [
        requirement("flake8"),
    ],
)

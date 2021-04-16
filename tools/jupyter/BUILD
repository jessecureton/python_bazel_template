load("@pip//:requirements.bzl", "requirement")
load("//tools/rules/python:defs.bzl", "${project}_py_binary")

${project}_py_binary(
    name = "jupyter",
    srcs = ["main.py"],
    main = "main.py",
    deps = [
        # Include the main ${project} binary so we can call things within it
        "//${project}",
        requirement("notebook"),
    ],
)

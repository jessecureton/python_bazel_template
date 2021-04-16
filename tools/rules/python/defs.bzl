load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")

# These rules exist primarily as a way to provide a simple `main` wrapper for
# py_test rules, so we don't have to provide a main stub for every test target.
# All macros here except ${project}_py_test are passthroughs that exist only for
# consistency in target naming

def ${project}_py_test(name, **kwargs):
    """
    A macro that runs pytest tests by using a test runner.

    This is modified from the examples at bazelbuild/rules_python/#240 and
    `py_pytest_test` at https://github.com/ali5h/rules_pip/blob/master/defs.bzl
    Primarily it changes the test runner to better support some Bazel features

    Args:
        name: A unique name for this target.
        **kwargs: are passed to py_test, with srcs and deps attrs modified
    """

    if "main" in kwargs:
        fail("if you need to specify main, use py_test directly")

    deps = kwargs.pop("deps", []) + ["//tools/rules/python:test_runner"]
    srcs = kwargs.pop("srcs", []) + ["//tools/rules/python:test_runner"]
    args = kwargs.pop("args", [])

    # failsafe, pytest won't work otw.
    for src in srcs:
        if name == src.split("/", 1)[0]:
            fail("rule name (%s) cannot be the same as the" +
                 "directory of the tests (%s)" % (name, src))

    py_test(
        name = name,
        srcs = srcs,
        main = "test_runner.py",
        deps = deps,
        args = args,
        **kwargs
    )

def ${project}_py_library(*args, **kwargs):
    py_library(*args, **kwargs)

def ${project}_py_binary(*args, **kwargs):
    py_binary(*args, **kwargs)

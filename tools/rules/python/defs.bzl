load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")
#load("@io_bazel_rules_docker//python3:image.bzl", "py3_image")
#load("@io_bazel_rules_docker//lang:image.bzl", "app_layer")

# These rules exist primarily as a way to provide a simple `main` wrapper for
# py_test rules, so we don't have to provide a main stub for every test target.

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
    """
    A pass-through macro for the upstream py_library rules.
    """
    py_library(*args, **kwargs)

def ${project}_py_binary(name, **kwargs):
    """
    A macro that generates py_binary targets for the host and containers.

    This is effectively a pass-through to generate a normal py_binary target and
    an additional py_binary using the container toolchain for use by `${project}_py_binary`.

    Args:
        name: A unique name for this target.
        **kwargs: are passed to both generated py_binary targets
    """
    py_binary(name = name, **kwargs)

    # Create an additional copy of the binary using the docker toolchain. This allows us to
    # hugely simplify ${project}_py_image and pass in an existing binary target, since it's
    # difficult to create a new binary with different parameters from an existing one.
    #py_binary(
    #name = name + "_docker_binary",
    #exec_compatible_with = ["@io_bazel_rules_docker//platforms:run_in_container"],
    #**kwargs
    #)

def ${project}_py_image(name, binary = None, base = None, deps = [], layers = [], **kwargs):
    """
    A macro that generates a docker container to run a py_binary target.

    Args:
        name: A unique name for this target
        binary (optional): A `${project}_py_binary` target to run in the container
        layers (optional): Additional layers to bundle into the container.
        deps (optional): Only valid if `binary` is not provided. The dependencies of the binary.
        srcs (optional): Only valid if `binary` is not provided. The sources of the binary.
        **kwargs: are passed to the new py_binary rule, if one is not created

    Examples:
        # Providing an existing `${project}_py_binary`
        ${project}_py_image(
            name = "${project}_container_bin",
            binary = ":${project}",
            visibility = ["//visibility:public"],
        )

        # Directly providing python sources to run
        ${project}_py_image(
            name = "${project}_container_src",
            srcs = ["main.py"],
            main = "main.py",
            deps = [
                requirement("numpy"),
            ],
            visibility = ["//visibility:public"],
        )
    """
    pass

#
#    # If the user didn't provide a binary, configure a new one for them.
#    if binary == None:
#        binary = name + "_docker_binary"
#
#        py_binary(
#            name = binary,
#            python_version = "PY3",
#            deps = deps + layers,
#            exec_compatible_with = ["@io_bazel_rules_docker//platforms:run_in_container"],
#            **kwargs
#        )
#    else:
#        # We can't use a provider in a macro, so instead we use the implicit output from the
#        # ${project}_py_binary that sets up an additional binary with the right toolchain
#        binary = binary + "_docker_binary"
#
#    # From here on out this is effectively identical to the upstream rules_docker py3_image macro
#
#    base = base or "//:hermetic_python_base_image"
#    tags = kwargs.get("tags", None)
#    for index, dep in enumerate(layers):
#        base = app_layer(name = "%s.%d" % (name, index), base = base, dep = dep, tags = tags)
#        base = app_layer(name = "%s.%d-symlinks" % (name, index), base = base, dep = dep, binary = binary, tags = tags)
#
#    visibility = kwargs.get("visibility", None)
#    app_layer(
#        name = name,
#        base = base,
#        entrypoint = ["/usr/bin/python"],
#        binary = binary,
#        visibility = visibility,
#        tags = tags,
#        args = kwargs.get("args"),
#        data = kwargs.get("data"),
#        testonly = kwargs.get("testonly"),
#        # The targets of the symlinks in the symlink layers are relative to the
#        # workspace directory under the app directory. Thus, create an empty
#        # workspace directory to ensure the symlinks are valid. See
#        # https://github.com/bazelbuild/rules_docker/issues/161 for details.
#        create_empty_workspace_dir = True,
#    )

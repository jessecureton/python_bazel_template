load("@aspect_bazel_lib//lib:tar.bzl", "mtree_spec", "tar")
load("@aspect_bazel_lib//lib:transitions.bzl", "platform_transition_filegroup")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_tarball")
load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")

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

def _py_layers(name, binary):
    """
    Create three layers for a py_binary target: interpreter, third-party dependencies, and application code.

    This allows a container image to have smaller uploads, since the application layer usually changes more
    than the other two.

    Args:
        name: Prefix for generated targets, to ensure they are unique within the package.
        binary: The name of the ${project}_py_binary to bundle in the container.

    Returns:
        A list of labels for the layers, which are tar files
    """

    # Produce layers in this order, as the app changes most often
    layers = ["interpreter", "packages", "app"]

    # Produce the manifest for a tar file of our py_binary, but don't tar it up yet, so we can split
    # into fine-grained layers for better docker performance.
    mtree_spec(
        name = name + ".mf",
        srcs = [binary],
    )

    # match *only* external repositories that have the string "python"
    # e.g. this will match
    #   `/hello_world/hello_world_bin.runfiles/rules_python~0.21.0~python~python3_9_aarch64-unknown-linux-gnu/bin/python3`
    # but not match
    #   `/hello_world/hello_world_bin.runfiles/_main/python_app`
    PY_INTERPRETER_REGEX = "\\.runfiles/.*python.*-.*"

    # match *only* external pip like repositories that contain the string "site-packages"
    SITE_PACKAGES_REGEX = "\\.runfiles/.*/site-packages/.*"

    native.genrule(
        name = name + ".interpreter_tar_manifest",
        srcs = [name + ".mf"],
        outs = [name + ".interpreter_tar_manifest.spec"],
        cmd = "grep '{}' $< >$@".format(PY_INTERPRETER_REGEX),
    )

    native.genrule(
        name = name + ".packages_tar_manifest",
        srcs = [name + ".mf"],
        outs = [name + ".packages_tar_manifest.spec"],
        cmd = "grep '{}' $< >$@".format(SITE_PACKAGES_REGEX),
    )

    # Any lines that didn't match one of the two grep above
    native.genrule(
        name = name + ".app_tar_manifest",
        srcs = [name + ".mf"],
        outs = [name + ".app_tar_manifest.spec"],
        cmd = "grep -v '{}' $< | grep -v '{}' >$@".format(SITE_PACKAGES_REGEX, PY_INTERPRETER_REGEX),
    )

    result = []
    for layer in layers:
        layer_target = "{}.{}_layer".format(name, layer)
        result.append(layer_target)
        tar(
            name = layer_target,
            srcs = [binary],
            mtree = "{}.{}_tar_manifest".format(name, layer),
        )

    return result

def ${project}_py_image(name, binary, image_tags, tars = [], base = None, entrypoint = None, **kwargs):
    """
    A macro that generates an OCI container image to run a py_binary target.

    The created target can be passed on to anything that expects an oci_image target, such as `oci_push`.

    An implicit `oci_tarball` target is created for the image in question, which can be used to load
    this image into a running docker daemon automatically for testing. This is named `name + "_load_docker"`.

        ```sh
        bazel run //path/to:<my_oci_image>_load_docker
        ```

    Args:
        name: A unique name for this target.
        binary: The name of the ${project}_py_binary to bundle in the container.
        image_tags: A list of tags to apply to the image.
        tars: A list of additional tar files to include in the image.
        base: The base image to use for the container. If not provided, the default is "@python_base".
        entrypoint: The entrypoint for the container. If not provided, it is inferred from the binary.
        **kwargs: are passed to oci_image

    Example:
        ${project}_py_image(
            name = "my_oci_image",
            binary = "//path/to:my_py_binary",
            tars = ["//path/to:my_extra_tar"],
            base = "@python_base",
            entrypoint = ["/my_py_binary/my_py_binary"],
            image_tags = ["my-tag:latest"],
        )
    """

    # NOTE: We would ideally use the @distroless_base image here, which is about 140MB smaller,
    # but rules_python depends on the host python toolchain to start a py_binary, so we need to
    # use a base image that ships python.
    #
    # The rules_oci python example[1] instead uses aspect-build/rules_py, which is an improved
    # set of python rules that has no dependencies on a host python. If we want to get to a pure
    # distroless image, we should consider migrating to that.
    #
    # [1] - https://github.com/aspect-build/bazel-examples/tree/main/oci_python_image
    base = base or "@python_base"

    # If the user didn't provide an entrypoint, infer the one for the binary
    bin_name = binary.split(":")[1]
    workspace_path = ""
    if binary.startswith("//"):
        workspace_path = binary.split(":")[0][2:]
    else:
        workspace_path = native.package_name()
    entrypoint = entrypoint or ["/{}/{}".format(workspace_path, bin_name)]

    # Define the image we want to provide
    oci_image(
        name = name + "_base_img",
        tars = tars + _py_layers(name, binary),
        base = base,
        entrypoint = entrypoint,
        **kwargs
    )

    # Transition the image to the platform we're building for
    platform_transition_filegroup(
        name = name,
        srcs = [name + "_base_img"],
        target_platform = select({
            "@platforms//cpu:arm64": "//tools/platforms:container_aarch64_linux",
            "@platforms//cpu:x86_64": "//tools/platforms:container_x86_64_linux",
        }),
    )

    # Create a tarball that can be loaded into a docker daemon
    oci_tarball(
        name = name + "_load_docker",
        image = name,
        repo_tags = image_tags,
    )

load("@aspect_bazel_lib//lib:tar.bzl", "mtree_spec", "tar")
load("@aspect_bazel_lib//lib:transitions.bzl", "platform_transition_filegroup")
load("@rules_go//go:def.bzl", "go_binary", "go_library", "go_test")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_tarball")

def ${project}_go_test(name, **kwargs):
    """
    A macro that runs golang tests.

    It is a passthrough shim to allow later customization of the go_test rule
    from a single location.

    Args:
        name: The name of the test.
        kwargs: Additional arguments to pass to go_test.
    """
    go_test(
        name = name,
        **kwargs
    )

def ${project}_go_library(name, **kwargs):
    """
    A macro that creates a golang library.

    It is a passthrough shim to allow later customization of the go_library rule
    from a single location.

    Args:
        name: The name of the library.
        kwargs: Additional arguments to pass to go_library.
    """
    go_library(
        name = name,
        **kwargs
    )

def ${project}_go_binary(name, **kwargs):
    """
    A macro that creates a golang binary.

    It is a passthrough shim to allow later customization of the go_binary rule
    from a single location.

    Args:
        name: The name of the binary.
        kwargs: Additional arguments to pass to go_binary.
    """
    go_binary(
        name = name,
        **kwargs
    )

def _go_layers(name, binary):
    """
    Create the layers for a go_binary target.

    By intelligently bunding layers, we can isolate application changes from other
    layers, which can speed up the build process.

    At the moment, we just provide a single layer for the binary+runfiles, but
    we could improve this in the future similar to how the `${project}_py_image` macro
    divides up layers.

    Args:
        name: Prefix for generated targets, to ensure they are unique within the package.
        binary: The name of the ${project}_go_binary to bundle in the container.

    Returns:
        A list of labels for the generated layers, which are tar files.
    """
    # The order of the layers here should be from least to most frequently changing.
    layers = ["app"]

    # Produce a manifest for a tar file of our go_binary, but don't tar it up yet. We will split
    # into fine-grained layers later for better docker performance.
    mtree_spec(
        name = name + ".mf",
        srcs = [binary],
    )

    # This all basically works by defining separate regexes for paths that should be included in
    # each layer. The mtree spec is then used to create a tar file for each layer.
    # Since we only bundle an app layer right now, we just use a catch-all regex for it.
    APP_LAYER_REGEX = ".*"

    # Create the tar manifest specs for each layer by taking the base manifest and
    # filtering it with the appropriate regex.
    native.genrule(
        name = name + ".app_tar_manifest",
        srcs = [name + ".mf"],
        outs = [name + ".app_tar_manifest_spec"],
        cmd = "grep '{}' $< >$@".format(APP_LAYER_REGEX),
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

def ${project}_go_image(name, binary, image_tags, include_runfiles = True, tars = [], base = None, entrypoint = None, **kwargs):
    """
    A macro that generates an OCI container image to run a go_binary target.

    The created target can be passed to anything that expects an oci_iamge target, such as `oci_push`.

    An implicit `oci_tarball` target is created for the image in question, which can be used to load
    this image into a running docker daemon automatically for testing. This is named `name + "_load_docker"`.

        ```sh
        bazel run //path/to:<my_oci_image>_load_docker
        ```

    Args:
        name: A unique name for this target.
        binary: The name of the ${project}_go_binary to bundle in the container.
        image_tags: A list of tags to apply to the image.
        include_runfiles: Whether to include the runfiles in the image. If not provided, the default is True.
        tars: A list of additional tar files to include in the image.
        base: The base image to use for the container. If not provided, the default is "@distroless_base".
        entrypoint: The entrypoint for the container. If not provided, it is inferred from the binary.
        **kwargs: are passed to oci_image

    Example:
        ${project}_go_image(
            name = "my_image",
            binary = "//path/to:my_py_binary",
            tars = ["//path/to:my_extra_tar"],
            base = "@distroless_base",
            entrypoint = ["/my_binary"],
            image_tags = ["my-tag:latest"],
        )
    """
    base = base or "@distroless_base"

    # If the user didn't provide an entrypoint, we can infer it from the binary.
    bin_name = binary.split(":")[1]
    workspace_path = ""
    if binary.startswith("//"):
        workspace_path = binary.split(":")[0][2:]
    else:
        workspace_path = native.package_name()
    # Outputs from go_binary targets add an extra directory with a random underscore to the path
    entrypoint = entrypoint or ["/{}/{}_/{}".format(workspace_path, bin_name, bin_name)]

    # Define the image we want to provide
    oci_image(
        name = name + "_base_image",
        tars = tars + _go_layers(name, binary),
        base = base,
        entrypoint = entrypoint,
        **kwargs
    )

    # Transition the image to the platform we are building for.
    platform_transition_filegroup(
        name = name,
        srcs = [name + "_base_image"],
        target_platform = select({
            "@platforms//cpu:arm64": "//tools/platforms:container_aarch64_linux",
            "@platforms//cpu:x86_64": "//tools/platforms:container_x86_64_linux",
        }),
    )

    # Create a tarball for the image, so we can load it into a running docker daemon.
    oci_tarball(
        name = name + "_load_docker",
        image = name,
        repo_tags = image_tags,
    )

load("@rules_python//python:defs.bzl", "py_runtime_pair")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")
load("@io_bazel_rules_docker//container:image.bzl", "container_image")

# Set up our pip requirements
compile_pip_requirements(
    name = "requirements",
    #extra_args = ["--allow-unsafe"],
    requirements_in = "requirements.in",
    requirements_txt = "requirements_lock.txt",
)

# Set up our default python3 runtime
py_runtime(
    name = "python3_runtime",
    files = ["@python_interpreter//:files"],
    interpreter = "@python_interpreter//:python_bin",
    python_version = "PY3",
)

py_runtime_pair(
    name = "hermetic_py_runtime_pair",
    py2_runtime = None,
    py3_runtime = ":python3_runtime",
)

toolchain(
    name = "hermetic_py_toolchain",
    toolchain = ":hermetic_py_runtime_pair",
    toolchain_type = "@bazel_tools//tools/python:toolchain_type",
)


# Set up a container-local interpreter, since our container runtime has its own
# equivalent hermetic runtime internally.
py_runtime(
    name = "container_python3_runtime",
    interpreter_path = "/usr/local/bin/python3",
    python_version = "PY3",
)

py_runtime_pair(
    name = "container_py_runtime_pair",
    py2_runtime = None,
    py3_runtime = ":container_python3_runtime",
)

toolchain(
    name = "container_py_toolchain",
    exec_compatible_with = [
        "@io_bazel_rules_docker//platforms:run_in_container",
    ],
    toolchain = ":container_py_runtime_pair",
    toolchain_type = "@bazel_tools//tools/python:toolchain_type",
)

container_image(
    name = "hermetic_python_base_image",
    base = "@_hermetic_python_base_image_base//image",
    # The `py3_image` rules hardcode an entrypoint of `/usr/bin/python`, rather than
    # accounting for the in-container toolchain. This is dumb, but we can craft a
    # symlink here manually to make a lightweight container like alpine work. The other
    # alternative would be using `python3-buster` upstream images, but these roughly 15x
    # the size of the container.
    # See https://github.com/bazelbuild/rules_docker/issues/1247
    symlinks = {
        "/usr/bin/python": "/usr/local/bin/python",
    },
    visibility = ["//visibility:public"],
)

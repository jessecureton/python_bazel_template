########################################
# Fetch the python rules
########################################

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

http_archive(
    name = "rules_python",
    sha256 = "c68bdc4fbec25de5b5493b8819cfc877c4ea299c0dcb15c244c5a00208cde311",
    strip_prefix = "rules_python-0.31.0",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.31.0/rules_python-0.31.0.tar.gz",
)

load("@rules_python//python:repositories.bzl", "py_repositories", "python_register_toolchains")

py_repositories()

PY_VERSION = "3.11.6"

_SANI_PY_VERSION = PY_VERSION.replace(".", "_")

# We have to register our in-container toolchain prior to registering the hermetic toolchain,
# otherwise since the hermetic toolchain defines no constraints it will end up running in the
# container, which breaks on macOS
register_toolchains("//:container_py_toolchain")

python_register_toolchains(
    name = "python" + _SANI_PY_VERSION,
    python_version = PY_VERSION,
)

########################################
# Set up pip requirements rules
########################################

load("@rules_python//python:pip.bzl", "pip_parse")

pip_parse(
    name = "pip",

    # (Optional) You can provide extra parameters to pip.
    # Here, make pip output verbose (this is usable with `quiet = False`).
    #extra_pip_args = ["-v"],

    # (Optional) You can exclude custom elements in the data section of the generated BUILD files for pip packages.
    # Exclude directories with spaces in their names in this example (avoids build errors if there are such directories).
    #pip_data_exclude = ["**/* */**"],

    # (Optional) You can provide a python_interpreter (path) or a python_interpreter_target (a Bazel target, that
    # acts as an executable). The latter can be anything that could be used as Python interpreter. E.g.:
    # 1. Python interpreter that you compile in the build file (as above in @python_interpreter).
    # 2. Pre-compiled python interpreter included with http_archive
    # 3. Wrapper script, like in the autodetecting python toolchain.
    python_interpreter_target = "@python" + _SANI_PY_VERSION + "_host//:python",

    # (Optional) You can set quiet to False if you want to see pip output.
    #quiet = False,
    requirements_lock = "//:requirements_lock.txt",
)

# Load the starlark macro which will define your dependencies.
load("@pip//:requirements.bzl", "install_deps")

# Call it to define repos for your requirements.
install_deps()

########################################
# Prepare a hermetic Golang interpreter
#
# Includes Golang, Gazelle, and protobuf.
#
# See these links for details:
#    - https://github.com/bazelbuild/rules_go
########################################
http_archive(
    name = "io_bazel_rules_go",
    sha256 = "80a98277ad1311dacd837f9b16db62887702e9f1d1c4c9f796d0121a46c8e184",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.46.0/rules_go-v0.46.0.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.46.0/rules_go-v0.46.0.zip",
    ],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "32938bda16e6700063035479063d9d24c60eda8d79fd4739563f50d331cb3209",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.35.0/bazel-gazelle-v0.35.0.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.35.0/bazel-gazelle-v0.35.0.tar.gz",
    ],
)

http_archive(
    name = "com_google_protobuf",
    sha256 = "d19643d265b978383352b3143f04c0641eea75a75235c111cc01a1350173180e",
    strip_prefix = "protobuf-25.3",
    urls = [
        "https://mirror.bazel.build/github.com/protocolbuffers/protobuf/archive/v25.3.tar.gz",
        "https://github.com/protocolbuffers/protobuf/archive/refs/tags/v25.3.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

go_rules_dependencies()

go_register_toolchains(version = "1.22.0")

gazelle_dependencies()

protobuf_deps()

########################################
# Prepare a hermetic Buildifier
########################################
http_archive(
    name = "com_github_bazelbuild_buildtools",
    sha256 = "9a5df8cc8a3230f00583dc8dd6a8f5519246d845623632333253ec6b848070d7",
    strip_prefix = "buildtools-6.4.0",
    url = "https://github.com/bazelbuild/buildtools/archive/refs/tags/v6.4.0.zip",
)

########################################
# Set up rules_docker
########################################
http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "b1e80761a8a8243d03ebca8845e9cc1ba6c82ce7c5179ce2b295cd36f7e394bf",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.25.0/rules_docker-v0.25.0.tar.gz"],
)

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)

container_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

container_deps()

load(
    "@io_bazel_rules_docker//python3:image.bzl",
    _py_image_repos = "repositories",
)
load("@io_bazel_rules_docker//container:container.bzl", "container_pull")

container_pull(
    name = "_hermetic_python_base_image_base",
    registry = "docker.io",
    repository = "library/python",
    tag = "{0}-alpine".format(PY_VERSION),
)

########################################
# Set up rules_pkg
########################################

http_archive(
    name = "rules_pkg",
    sha256 = "d250924a2ecc5176808fc4c25d5cf5e9e79e6346d79d5ab1c493e289e722d1d0",
    urls = [
        "https://github.com/bazelbuild/rules_pkg/releases/download/0.10.1/rules_pkg-0.10.1.tar.gz",
    ],
)

load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")

rules_pkg_dependencies()

# Rules Docker somehow requires this to happen as the last line of the file
_py_image_repos()

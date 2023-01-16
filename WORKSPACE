########################################
# Fetch the python rules
########################################

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

http_archive(
    name = "rules_python",
    sha256 = "a868059c8c6dd6ad45a205cca04084c652cfe1852e6df2d5aca036f6e5438380",
    strip_prefix = "rules_python-0.14.0",
    url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.14.0.tar.gz",
)

########################################
# Prepare a hermetic python interpreter
# See these links for details:
#    - https://github.com/kku1993/bazel-hermetic-python
#    - https://thethoughtfulkoala.com/posts/2020/05/16/bazel-hermetic-python.html
########################################

PY_VERSION = "3.11.0"

BUILD_DIR = "/tmp/bazel-python-{0}".format(PY_VERSION)

# Special logic for building python interpreter with OpenSSL from homebrew.
# See https://devguide.python.org/setup/#macos-and-os-x
# Note: Enabling optimizations yields a pretty snappy Python3 instance
# However if it causes problems please disable rather than try and solve them (for your own sanity)
_py_configure = """
if [[ "$OSTYPE" == "darwin"* ]]; then
    cd {0} && ./configure --prefix={0}/bazel_install --with-openssl=$(brew --prefix openssl) --enable-optimizations
else
    cd {0} && ./configure --prefix={0}/bazel_install --enable-optimizations
fi
""".format(BUILD_DIR)

# MacOS `ar` does not support deterministic mode (the -D flag).
# We'll just sorta handwave around the implications of this for hermeticity there for now.
_py_make = """
if [[ "$OSTYPE" == "darwin"* ]]; then
    cd {0} && SOURCE_DATE_EPOCH=0 make -j $(nproc) ARFLAGS='rv'
else
    cd {0} && SOURCE_DATE_EPOCH=0 make -j $(nproc) ARFLAGS='rvD'
fi
""".format(BUILD_DIR)

http_archive(
    name = "python_interpreter",
    build_file_content = """
exports_files(["python_bin"])
filegroup(
    name = "files",
    srcs = glob(["bazel_install/**"], exclude = ["**/* *"]),
    visibility = ["//visibility:public"],
)
""",
    patch_cmds = [
        # Create a build directory outside of bazel so we get consistent path in
        # the generated files. See kku1993/bazel-hermetic-python#8
        "mkdir -p {0}".format(BUILD_DIR),
        "cp -r * {0}".format(BUILD_DIR),
        # Build python.
        _py_configure,
        # Produce deterministic binary by using a fixed build timestamp and
        # running `ar` in deterministic mode. See kku1993/bazel-hermetic-python#7
        _py_make,
        "cd {0} && make install".format(BUILD_DIR),
        # Copy the contents of the build directory back into bazel.
        "rm -rf * && mv {0}/* .".format(BUILD_DIR),
        "ln -s bazel_install/bin/python3 python_bin",
    ],
    sha256 = "a57dc82d77358617ba65b9841cee1e3b441f386c3789ddc0676eca077f2951c3",
    strip_prefix = "Python-{0}".format(PY_VERSION),
    urls = ["https://www.python.org/ftp/python/{0}/Python-{0}.tar.xz".format(PY_VERSION)],
)

# We have to register our in-container toolchain prior to registering the hermetic toolchain,
# otherwise since the hermetic toolchain defines no constraints it will end up running in the
# container, which breaks on macOS
register_toolchains("//:container_py_toolchain")

register_toolchains("//:hermetic_py_toolchain")

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
    python_interpreter_target = "@python_interpreter//:python_bin",

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
    sha256 = "099a9fb96a376ccbbb7d291ed4ecbdfd42f6bc822ab77ae6f1b5cb9e914e94fa",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.35.0/rules_go-v0.35.0.zip",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.35.0/rules_go-v0.35.0.zip",
    ],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "501deb3d5695ab658e82f6f6f549ba681ea3ca2a5fb7911154b5aa45596183fa",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.26.0/bazel-gazelle-v0.26.0.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.26.0/bazel-gazelle-v0.26.0.tar.gz",
    ],
)

http_archive(
    name = "com_google_protobuf",
    sha256 = "0aa7df8289c957a4c54cbe694fbabe99b180e64ca0f8fdb5e2f76dcf56ff2422",
    strip_prefix = "protobuf-21.9",
    urls = [
        "https://mirror.bazel.build/github.com/protocolbuffers/protobuf/archive/v21.9.tar.gz",
        "https://github.com/protocolbuffers/protobuf/archive/refs/tags/v21.9.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

go_rules_dependencies()

go_register_toolchains(version = "1.19.1")

gazelle_dependencies()

protobuf_deps()

########################################
# Prepare a hermetic Buildifier
########################################
http_archive(
    name = "com_github_bazelbuild_buildtools",
    sha256 = "932160d5694e688cb7a05ac38efba4b9a90470c75f39716d85fb1d2f95eec96d",
    strip_prefix = "buildtools-4.0.1",
    url = "https://github.com/bazelbuild/buildtools/archive/4.0.1.zip",
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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_pkg",
    sha256 = "038f1caa773a7e35b3663865ffb003169c6a71dc995e39bf4815792f385d837d",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_pkg/releases/download/0.4.0/rules_pkg-0.4.0.tar.gz",
        "https://github.com/bazelbuild/rules_pkg/releases/download/0.4.0/rules_pkg-0.4.0.tar.gz",
    ],
)

load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")

rules_pkg_dependencies()

_py_image_repos()

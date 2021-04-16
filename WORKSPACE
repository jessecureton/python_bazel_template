########################################
# Fetch the python rules
########################################

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "rules_python",
    commit = "6135186f93d46ab8551d9fe52bac97bf0c2de1ab",
    remote = "https://github.com/bazelbuild/rules_python.git",
    shallow_since = "1613499313 +0100",
)

########################################
# Set up pip requirements rules
########################################

load("@rules_python//python:pip.bzl", "pip_install")

pip_install(
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

    # Uses the default repository name "pip"
    requirements = "//:requirements.txt",
)

########################################
# Prepare a hermetic python interpreter
# See these links for details:
#    - https://github.com/kku1993/bazel-hermetic-python
#    - https://thethoughtfulkoala.com/posts/2020/05/16/bazel-hermetic-python.html
########################################

# Special logic for building python interpreter with OpenSSL from homebrew.
# See https://devguide.python.org/setup/#macos-and-os-x
# Note: Enabling optimizations yields a pretty snappy Python3 instance
# However if it causes problems please disable rather than try and solve them (for your own sanity)
_py_configure = """
if [[ "$OSTYPE" == "darwin"* ]]; then
    ./configure --prefix=$(pwd)/bazel_install --with-openssl=$(brew --prefix openssl) --enable-optimizations
else
    ./configure --prefix=$(pwd)/bazel_install --enable-optimizations
fi
"""

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
        "mkdir $(pwd)/bazel_install",
        _py_configure,
        "make -j",
        "make install",
        "ln -s bazel_install/bin/python3 python_bin",
    ],
    sha256 = "3c2034c54f811448f516668dce09d24008a0716c3a794dd8639b5388cbde247d",
    strip_prefix = "Python-3.9.2",
    urls = ["https://www.python.org/ftp/python/3.9.2/Python-3.9.2.tar.xz"],
)

register_toolchains("//:hermetic_py_toolchain")

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
    sha256 = "6f111c57fd50baf5b8ee9d63024874dd2a014b069426156c55adbf6d3d22cb7b",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.25.0/rules_go-v0.25.0.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.25.0/rules_go-v0.25.0.tar.gz",
    ],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "b85f48fa105c4403326e9525ad2b2cc437babaa6e15a3fc0b1dbab0ab064bc7c",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.2/bazel-gazelle-v0.22.2.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.22.2/bazel-gazelle-v0.22.2.tar.gz",
    ],
)

http_archive(
    name = "com_google_protobuf",
    sha256 = "9748c0d90e54ea09e5e75fb7fac16edce15d2028d4356f32211cfa3c0e956564",
    strip_prefix = "protobuf-3.11.4",
    urls = ["https://github.com/protocolbuffers/protobuf/archive/v3.11.4.zip"],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

go_rules_dependencies()

go_register_toolchains(version = "1.15.5")

gazelle_dependencies()

protobuf_deps()

########################################
# Prepare a hermetic Buildifier
########################################
http_archive(
    name = "com_github_bazelbuild_buildtools",
    sha256 = "f5b666935a827bc2b6e2ca86ea56c796d47f2821c2ff30452d270e51c2a49708",
    strip_prefix = "buildtools-3.5.0",
    url = "https://github.com/bazelbuild/buildtools/archive/3.5.0.zip",
)

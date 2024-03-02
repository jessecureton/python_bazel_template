# Intro
An opinionated template repo for multi-lingual projects using Bazel, built around the principle that
wherever possible projects should be hermetic and reproducible. It includes:

- Automated linting for Bazel, Python, Golang, and Markdown sources with Buildifier, Flake8, Black, and Isort, Prettier, and `go fmt`.
- Python test helpers to simplify unit test targets
- Hermetic Python & Golang toolchains
- Hermetic pip dependencies sourced from requirements.txt
- Python & Golang Docker image support, including a matching runtime version as the hermetic toolchains.

It does not seek to provide a continual submodule that can pick up upstream changes from the
template, but is more like a `create-react-app` template where you can eject from the template
and proceed with your project. That being said, if you don't change any paths you can likely
`git cherry-pick` or otherwise patch in changes from upstream and then run `eject.sh` again
to update paths for your project.

# Setup

1. Install Bazel. Instructions for doing so can be found here:
   https://docs.bazel.build/versions/master/install.html
2. Run the template eject script, providing your project's name. `./eject.sh <project_name>`

**Note to Linux users:**
`py_binary()` uses the host's Python as a bootstrap for execing the hermetic Python under Bazel.
If you only have python3 installed you will need to symlink python to python3 (i.e. ln -s
/usr/bin/python3 /usr/bin/python)

# Development

Pull requests are welcome! Open one against this repo and it will be reviewed & merged.

## Adding New Dependencies

### Python

To add a new python pip dependency:

1. Add the new dependency to `requirements.in`
2. Run `bazel run //:requirements.update`
3. Commit the updates to `requirements_lock.txt`

### Golang

To add a new golang dependency:

1. Begin using the dependency in your Go code
1. Run `bazel run @rules_go//go get <dependency>` to add the dependency to go.mod
1. Run `bazel run @rules_go//go mod tidy` to pull in the transitive deps and update go.mod to show it as used
1. Run `bazel run //:gazelle` to update your build files. This will print a warning like the following
    ```
    $ bazel run //:gazelle
    WARNING: /Users/jcureton/development/personal/python_bazel_template/MODULE.bazel:39:24: The module extension go_deps defined in @gazelle//:extensions.bzl reported incorrect imports of repositories via use_repo():

    Not imported, but reported as direct dependencies by the extension (may cause the build to fail):
        io_rsc_quote

    ** You can use the following buildozer command to fix these issues:

    buildozer 'use_repo_add @gazelle//:extensions.bzl go_deps io_rsc_quote' //MODULE.bazel:all
    ```
1. Run the printed buildozer command with `bazel run -- //tools/buildozer ...`
1. Commit the updates to go.mod, go.sum, MODULE.bazel, MODULE.bazel.lock, and any build files.

## Linting

In general, lint by running the `lint.sh` script.

The first time you run lint, you'll see a warning like:
```
UserWarning: `known_${project}` setting is defined, but ${project} is not included in `sections`
config option: ('FUTURE', 'STDLIB', 'THIRDPARTY', '${project}', 'FIRSTPARTY', 'LOCALFOLDER').
```
To resolve this, open `pyproject.toml` in the repo root, and update the `<project>` reference in
`SECTIONS` on line 11 to be capitalized. This is a known issue with the basic templating script
used in the repo, and PRs are welcome if you have a resolution :)

You can manually run ${Buildifier/Flake8/Black/Isort} with the following if you want to, though
you'll have to handle paths manually to prevent them from working on the Bazel sandbox.

- `bazel run //tools/${tool}`

## Testing

Unit tests are run using the `bazel test` command. A test wrapper is provided that invokes `pytest`
with reasonable defaults and configures the entrypoint. You just write pytest test cases in normal
Python files, and pass these as `srcs` to a `${project}_py_test` rule. The test runner handles the rest.

## Language Support

Currently this Bazel workspace supports building/running on macOS and Linux. Windows support is
explicitly unscoped. The currently-supported languages are:

- Python
- Golang

### Python

#### Running an interactive python session
You can run an interactive python session via either an ipython shell or a Jupyter notebook. By
default, both include the `//${project}` bazel target so you can make use of ${project} code
interactively.

1. iPython - `bazel run //tools/ipython`. You'll be dropped into a python shell in the Bazel sandbox
2. Jupyter - `bazel run //tools/jupyter`. You'll be dropped into a Jupyter web interface. You can
   create a new Notebook to experiment. In general, consider these environments to be ephemeral, but
   if needed the notebook is created inside `bazel-bin/tools/jupyter/jupyter.runfiles/__main__`.
   Alternatively, consider downloading the notebook from the web UI if you will continue to need it.

By default this includes the `//${project}` target, so you can make use of ${project} code interactively

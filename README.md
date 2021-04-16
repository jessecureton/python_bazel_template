# Intro
An opinionated template repo for Python projects using Bazel, built around the principle that
wherever possible projects should be hermetic and reproducible. It includes:

- Automated linting for Bazel & Python sources with Buildifier, Flake8, Black, and Isort
- Python test helpers to simplify unit test targets
- Hermetic Python toolchain
- Hermetic pip dependencies sourced from requirements.txt

It does not seek to provide a continual submodule that can pick up upstream changes from the
template, but is more like a `create-react-app` template where you can eject from the template
and proceed with your project. That being said, if you don't change any paths you can likely
`git cherry-pick` or otherwise patch in changes from upstream and then run `eject.sh` again
to update paths for your project.

# Setup

1. Install Bazel. Instructions for doing so can be found here:
   https://docs.bazel.build/versions/master/install.html
2. Run the template eject script, providing your project's name. `./eject.sh <project_name>`

Note to Linux users:
* Python pip requires libssl-dev to be installed (sudo apt-get install libssl-dev).
* `py_binary()` uses the host's Python as a bootstrap for execing the hermetic Python under Bazel.
   If you only have python3 installed you will need to symlink python to python3
   (i.e. ln -s /usr/bin/python3 /usr/bin/python)

# Development

Pull requests are welcome! Open one against this repo and it will be reviewed & merged.

## Linting

In general, lint by running the `lint.sh` script.

You can manually run ${Buildifier/Flake8/Black/Isort} with the following if you want to, though
you'll have to handle paths manually to prevent them from working on the Bazel sandbox.

- `bazel run //tools/${tool}`

## Language Support

Currently this Bazel workspace supports building/running on macOS and Linux. Windows support is
explicitly unscoped. The currently-supported languages are:

- Python
- Golang
  - Golang is limited at the moment and mostly exists just for hermetic Buildifier. Additional work
    is likely required if you want to use arbitrary Go dependencies with Gazelle.

### Running an interactive python session
You can run an interactive python session via either an ipython shell or a Jupyter notebook. By
default, both include the `//${project}` bazel target so you can make use of ${project} code
interactively.

1. iPython - `bazel run //tools/ipython`. You'll be dropped into a python shell in the Bazel sandbox
2. Jupyter - `bazel run //tools/jupyter`. You'll be dropped into a Jupyter web interface. You can
   create a new Notebook to experiment. In general, consider these environments to be ephemeral, but
   if needed the notebook is created inside `bazel-bin/tools/jupyter/jupyter.runfiles/__main__`.
   Alternatively, consider downloading the notebook from the web UI if you will continue to need it.

By default this includes the `//${project}` target, so you can make use of ${project} code interactively

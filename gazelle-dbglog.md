# Intro

This is a log for debugging why the `python_*_naming_convention` directives don't work in my
project. The `libary` one seems to work, but the `binary` and `test` ones don't seem to and are just
ignored.

Actually, they aren't just ignored, but they seem to use the _python_ module name instead!

---

First experiment: can we reproduce in a trivial example? Attempting to reproduce using the upstream
example for bzlmod + gazelle[1]. Applying the following diff shows that this does work!

```diff
diff --git a/examples/bzlmod_build_file_generation/BUILD.bazel b/examples/bzlmod_build_file_generation/BUILD.bazel
index 33d01f4..fc14b34 100644
--- a/examples/bzlmod_build_file_generation/BUILD.bazel
+++ b/examples/bzlmod_build_file_generation/BUILD.bazel
@@ -62,30 +62,34 @@ gazelle_python_manifest(
 # - bazel run //:gazelle update
 # - bazel run //:gazelle fix
 # See: https://github.com/bazelbuild/bazel-gazelle#fix-and-update
+# gazelle:python_library_naming_convention $package_name$_py
+# gazelle:python_binary_naming_convention $package_name$_mybin
+# gazelle:python_test_naming_convention $package_name$_test_foo
 gazelle(
     name = "gazelle",
     gazelle = "@rules_python_gazelle_plugin//python:gazelle_binary",
 )
```

That this works is annoying, but does give me some hope that we can actually resolve it in our
project...

---

Next experiment: what if we use the upstream rules directly and not my own wrappers?

This did not work, unfortunately. I disabled the `map_kind` settings that redirect to my wrappers,
but that did not change the behavior.

---

Next experiment: what if we use only the python gazelle generator, and not the golang module? Doing
this by changing the `gazelle = ":gazelle_with_plugins"` target in ./BUILD to reference the upstream
one at `@rules_python_gazelle_plugin//python:gazelle_binary`

No dice - still see the same behavior.

---

Next experiment: What about the `gazelle:python_root` and `gazelle:resolve py` directives in
${project}/BUILD?

I removed these entirely, which included having to rename main_test.py to something that won't be
flagged as a python test. This still did not resolve the issue - the test target wasn't ccreated,
but the main target was unchanged.

---

Next experiment: Running the `:gazelle_python_manifest.update` target did not fix the issue.

---

Next experiment: What if we use the exact same local copy of the gazelle plugin that the test repo
is using?

Doing so with the following snippet

```
bazel_dep(name = "rules_python_gazelle_plugin", version = "0.0.0")

# The following starlark loads the gazelle plugin from the file system.
# For usual setups you should remove this local_path_override block.
local_path_override(
    module_name = "rules_python_gazelle_plugin",
    path = "/private/tmp/rules_python/gazelle",
)
```

Nope! Still the same issue :sob:

---

Next experiment: Rename the **main**.py and **test**.py files in the upstream repo to be named
main.py and main_test.py

_BINGO_ - this reproduced the issue for the first time in a bare repo. Unclear _why_, but it is
clearly related!

How can we probe for more?

1. Does it work the other way? If I rename my files, how do things behave? Let's name them **main**
   and **test**.

   Yes! Things behave more or less correctly now! we can even back out all the other fixes we were
   trying to eliminate variables and see that it works!

2. Is the `main` name special? What if they're just named like `foo` and have a **main** handler in
   them, will we get a binary target proper?

   NO! If we have them named `foo.py` and `foo_test.py` we still get these names ignored! This is
   _almost_ forming a picture of what's happening - it makes sense (sorta) that if you have a
   **main** handler in a non-**main**.py file, it probably needs to be its own bin target named with
   the name of that module - otherwise you can't have multiple py modules in one bazel module with a
   main handler.

   That's not a case that I will run in to, but it almost seems like having a main forces it into
   `file` generation mode, which _almost_ makes sense.

   Using these `foo` files generated the following targets

   ```py
   ${project}_py_binary(
       name = "foo",
       srcs = ["foo.py"],
       visibility = ["//${project}:__subpackages__"],
   )

   ${project}_py_library(
       name = "${project}_mylib",
       srcs = ["foo.py"],
       visibility = ["//${project}:__subpackages__"],
   )

   ${project}_py_test(
       name = "foo_test",
       srcs = ["foo_test.py"],
       deps = [":${project}"],
   )
   ```

   Spot the problem? The test target depends on a lib that doesn't exist! It looks like it ignored
   the library name format?

[1] - https://github.com/bazelbuild/rules_python/tree/main/examples/bzlmod_build_file_generation

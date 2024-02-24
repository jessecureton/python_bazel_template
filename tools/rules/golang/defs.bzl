load("@rules_go//go:def.bzl", "go_binary", "go_library", "go_test")

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

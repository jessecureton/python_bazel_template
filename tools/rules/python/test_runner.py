import os
import sys

import pytest


def main():
    pytest_args = [
        "--ignore=external",
        "-p",
        "no:cacheprovider",
    ]

    test_tempdir = os.environ.get("TEST_TMPDIR", None)
    if test_tempdir:
        test_tempdir = os.path.join(os.path.abspath(test_tempdir), "pytest_temp")
        pytest_args.append(f"--basetemp={test_tempdir}")

    test_filter = os.environ.get("TESTBRIDGE_TEST_ONLY", None)
    if test_filter:
        pytest_args.extend(["-k", test_filter])

    # Prepare all our collected arguments, searching the current directory
    pytest_args = pytest_args + sys.argv[2:] + ["."]

    print(f"Invoking pytest with: {pytest_args}")

    # Invoke pytest
    sys.exit(pytest.main(pytest_args))


if __name__ == "__main__":
    main()

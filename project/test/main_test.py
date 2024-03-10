import sys

from ${project}.main import main


def test_main(capsys):
    main()

    captured = capsys.readouterr()
    assert "Hello, world!" in captured.out


def test_hermetic_python():
    """Test that we're using the hermetic Python binary + venv from runfiles."""
    assert "bazel-out" in sys.executable
    assert ".runfiles" in sys.executable
    assert ".venv/bin/python" in sys.executable

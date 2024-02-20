import sys

from ${project}.main import main


def test_main(capsys):
    main()

    captured = capsys.readouterr()
    assert "Hello, world!" in captured.out


def test_hermetic_python():
    assert "runfiles/rules_python" in sys.executable

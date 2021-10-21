from ${project}.main import main


def test_main(capsys):
    main()

    captured = capsys.readouterr()
    assert captured.out == "Hello, world!\n"

"""Verify the installed package, not an accidental import from the checkout."""

import subprocess
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_installed_package_imports_outside_checkout(tmp_path: Path) -> None:
    with (ROOT / "pyproject.toml").open("rb") as stream:
        project_name = tomllib.load(stream)["project"]["name"]
    result = subprocess.run(
        [
            sys.executable,
            "-I",
            "-c",
            "import app; from importlib.metadata import distribution; "
            "import sys; assert distribution(sys.argv[1]); assert app.__file__",
            project_name,
        ],
        cwd=tmp_path,
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    assert result.stdout == ""
    assert result.stderr == ""

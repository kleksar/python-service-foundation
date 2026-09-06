"""Build from the sdist and import the resulting wheel outside the checkout."""

import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    with (ROOT / "pyproject.toml").open("rb") as stream:
        name = tomllib.load(stream)["project"]["name"]
    with tempfile.TemporaryDirectory(prefix="package-check-") as directory:
        temporary = Path(directory)
        artifacts = temporary / "dist"
        subprocess.run(
            ["uv", "build", "--no-build-isolation", "--out-dir", str(artifacts)],
            cwd=ROOT,
            check=True,
        )
        wheel = next(artifacts.glob("*.whl"))
        environment = temporary / "venv"
        subprocess.run(["uv", "venv", "--python", sys.executable, str(environment)], check=True)
        python = environment / ("Scripts/python.exe" if sys.platform == "win32" else "bin/python")
        requirements = subprocess.run(
            [
                "uv",
                "export",
                "--locked",
                "--no-dev",
                "--no-emit-project",
                "--format",
                "requirements-txt",
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        subprocess.run(
            ["uv", "pip", "sync", "--python", str(python), "--require-hashes", "-"],
            input=requirements.stdout,
            text=True,
            check=True,
        )
        subprocess.run(
            ["uv", "pip", "install", "--python", str(python), "--no-deps", str(wheel)], check=True
        )
        subprocess.run(
            [
                str(python),
                "-I",
                "-c",
                "import app; import sys; from importlib.metadata import distribution; "
                "from pathlib import Path; assert distribution(sys.argv[1]); "
                "assert app.__file__; assert Path(app.__file__).is_relative_to(sys.prefix)",
                name,
            ],
            cwd=temporary,
            check=True,
        )
    print("Built wheel installation passed.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Remove machine-bound Power BI Desktop security bindings from a PBIT."""

from __future__ import annotations

import argparse
import re
import shutil
import tempfile
import zipfile
from pathlib import Path


SECURITY_OVERRIDE = re.compile(
    rb'<Override\s+PartName="/SecurityBindings"[^>]*/>',
    flags=re.IGNORECASE,
)


def sanitize(source: Path, output: Path) -> None:
    if not zipfile.is_zipfile(source):
        raise ValueError(f"Not a ZIP-based PBIT package: {source}")

    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        prefix=f"{output.stem}-",
        suffix=".pbit",
        dir=output.parent,
        delete=False,
    ) as handle:
        temporary = Path(handle.name)

    try:
        with zipfile.ZipFile(source, "r") as reader, zipfile.ZipFile(
            temporary,
            "w",
        ) as writer:
            for info in reader.infolist():
                if info.filename == "SecurityBindings":
                    continue

                data = reader.read(info)
                if info.filename == "[Content_Types].xml":
                    data = SECURITY_OVERRIDE.sub(b"", data)

                writer.writestr(info, data)

        with zipfile.ZipFile(temporary, "r") as package:
            names = package.namelist()
            if "SecurityBindings" in names:
                raise RuntimeError("SecurityBindings was not removed.")
            if "DataModel" in names:
                raise RuntimeError("The template still contains an imported DataModel.")
            if SECURITY_OVERRIDE.search(package.read("[Content_Types].xml")):
                raise RuntimeError("The SecurityBindings content type remains.")

        shutil.move(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path, nargs="?")
    args = parser.parse_args()

    source = args.source.resolve()
    output = args.output.resolve() if args.output else source
    if output == source:
        with tempfile.NamedTemporaryFile(
            prefix=f"{source.stem}-raw-",
            suffix=".pbit",
            dir=source.parent,
            delete=False,
        ) as handle:
            staged_source = Path(handle.name)
        shutil.copy2(source, staged_source)
        try:
            sanitize(staged_source, source)
        finally:
            staged_source.unlink(missing_ok=True)
    else:
        sanitize(source, output)

    print(output)


if __name__ == "__main__":
    main()

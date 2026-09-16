#!/usr/bin/env python3
"""Synchronize selected M partitions from PBIP TMDL into a data-free PBIT."""

from __future__ import annotations

import argparse
import json
import shutil
import tempfile
import zipfile
from pathlib import Path


MODEL_PART = "DataModelSchema"
CHANGES_PART = "UnappliedChanges"


def extract_m_expression(path: Path, table_name: str) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    partition = f"\tpartition {table_name} = m"
    try:
        partition_index = lines.index(partition)
        source_index = lines.index("\t\tsource =", partition_index)
    except ValueError as error:
        raise ValueError(f"M partition for {table_name!r} was not found in {path}") from error

    expression: list[str] = []
    for line in lines[source_index + 1 :]:
        if line and not line.startswith("\t\t\t\t"):
            break
        expression.append(line[4:] if line else "")

    while expression and not expression[-1]:
        expression.pop()
    if not expression or expression[0] != "let":
        raise ValueError(f"Invalid M expression for {table_name!r} in {path}")
    return expression


def parse_utf16_json(data: bytes, part_name: str) -> tuple[dict, str]:
    text = data.decode("utf-16le")
    try:
        return json.loads(text), text
    except json.JSONDecodeError as error:
        raise ValueError(f"{part_name} is not valid UTF-16LE JSON") from error


def serialize_like(value: dict, original: str) -> bytes:
    if "\r\n" in original:
        text = json.dumps(value, ensure_ascii=False, indent=2).replace("\n", "\r\n")
    else:
        text = json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    return text.encode("utf-16le")


def synchronize(pbit: Path, mappings: dict[str, Path]) -> None:
    if not zipfile.is_zipfile(pbit):
        raise ValueError(f"Not a ZIP-based PBIT package: {pbit}")

    expressions = {
        table_name: extract_m_expression(path, table_name)
        for table_name, path in mappings.items()
    }

    with tempfile.NamedTemporaryFile(
        prefix=f"{pbit.stem}-sync-",
        suffix=".pbit",
        dir=pbit.parent,
        delete=False,
    ) as handle:
        temporary = Path(handle.name)

    try:
        with zipfile.ZipFile(pbit, "r") as reader:
            schema, schema_text = parse_utf16_json(
                reader.read(MODEL_PART), MODEL_PART
            )
            changes, changes_text = parse_utf16_json(
                reader.read(CHANGES_PART), CHANGES_PART
            )

            tables = {table["name"]: table for table in schema["model"]["tables"]}
            queries = {query["name"]: query for query in changes["queries"]}
            for table_name, expression in expressions.items():
                if table_name not in tables or table_name not in queries:
                    raise ValueError(f"{table_name!r} is missing from {pbit}")

                partitions = tables[table_name].get("partitions", [])
                if (
                    len(partitions) != 1
                    or partitions[0].get("source", {}).get("type") != "m"
                ):
                    raise ValueError(f"{table_name!r} must have exactly one M partition")

                partitions[0]["source"]["expression"] = expression
                query = queries[table_name]
                query["text"] = expression
                formula_state = json.loads(query["lastLoadedAsTableFormulaText"])
                formula_state["RootFormulaText"] = "\n".join(expression)
                query["lastLoadedAsTableFormulaText"] = json.dumps(
                    formula_state,
                    ensure_ascii=False,
                    separators=(",", ":"),
                )

            replacements = {
                MODEL_PART: serialize_like(schema, schema_text),
                CHANGES_PART: serialize_like(changes, changes_text),
            }

            with zipfile.ZipFile(temporary, "w") as writer:
                for info in reader.infolist():
                    writer.writestr(info, replacements.get(info.filename, reader.read(info)))
        shutil.move(temporary, pbit)
    finally:
        temporary.unlink(missing_ok=True)


def parse_mapping(value: str) -> tuple[str, Path]:
    table_name, separator, path = value.partition("=")
    if not separator or not table_name or not path:
        raise argparse.ArgumentTypeError("mapping must use TABLE=PATH")
    return table_name, Path(path).resolve()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pbit", type=Path)
    parser.add_argument(
        "--table",
        action="append",
        required=True,
        type=parse_mapping,
        metavar="TABLE=PATH",
    )
    args = parser.parse_args()

    mappings = dict(args.table)
    if len(mappings) != len(args.table):
        raise ValueError("Each table mapping must be unique")
    synchronize(args.pbit.resolve(), mappings)
    print(args.pbit.resolve())


if __name__ == "__main__":
    main()

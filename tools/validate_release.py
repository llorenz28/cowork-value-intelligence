#!/usr/bin/env python3
"""Validate the portable Cowork Value Intelligence release package."""

from __future__ import annotations

import csv
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
CURRENT_USERNAME = os.environ.get("USERNAME", "").strip().lower()
PACKAGED_PROFILE_PATH = re.compile(rb"(?i)[a-z]:[\\/]+users[\\/]+")
PUBLIC_LABEL_ID = "87867195-f2b8-4ac2-b0b6-6bb73cb33afc"
PBIT_SPECS = [
    ROOT / "adoption" / "Cowork Adoption Intelligence v2 Testing.pbit",
    ROOT / "value" / "Cowork Value V1 Testing.pbit",
]
PPTX = ROOT / "Cowork Value Intelligence V1.0 In Testing - Interpretation Storyboard.pptx"
VIDEO = ROOT / "media" / "Cowork-Value-Intelligence-Walkthrough.mp4"
SUBTITLES = ROOT / "media" / "Cowork-Value-Intelligence-Walkthrough.srt"
TRANSCRIPT = ROOT / "media" / "Cowork-Value-Intelligence-Walkthrough-transcript.md"
TIMELINE = ROOT / "media" / "Cowork-Value-Intelligence-Walkthrough-timeline.json"
SEGMENTS = ROOT / "media" / "walkthrough_segments.json"
PREVIEW = ROOT / "images" / "report-preview.gif"
SAMPLE = ROOT / "sample_data"
SAMPLE_ZIP = ROOT / "release" / "Cowork-Value-Intelligence-Sample-Data.zip"
ADOPTION_SAMPLE_ZIP = (
    ROOT / "adoption" / "release" / "Cowork-Adoption-Intelligence-Sample-Data.zip"
)
SAMPLE_ZIP_TIMESTAMP = (2026, 9, 6, 18, 0, 0)

EXPECTED = [
    *PBIT_SPECS,
    PPTX,
    VIDEO,
    SUBTITLES,
    TRANSCRIPT,
    TIMELINE,
    SEGMENTS,
    ROOT / "media" / "build_walkthrough.ps1",
    ROOT / "media" / "build_walkthrough_assets.py",
    ROOT / "media" / "README.md",
    PREVIEW,
    SAMPLE_ZIP,
    ADOPTION_SAMPLE_ZIP,
    ROOT / "src" / "Cowork Value Intelligence.pbip",
    ROOT / "docs" / "RELEASE_VERIFICATION.json",
]

TEXT_SUFFIXES = {
    ".csv",
    ".json",
    ".js",
    ".md",
    ".pbip",
    ".pbism",
    ".pbir",
    ".ps1",
    ".py",
    ".srt",
    ".tmdl",
    ".txt",
    ".xml",
}
TEXT_FILENAMES = {".gitignore", ".platform"}
SEMANTIC_MODEL_TABLE_DIRS = [
    ROOT / "src" / "Cowork Value Intelligence.SemanticModel" / "definition" / "tables",
    ROOT
    / "adoption"
    / "src"
    / "Cowork Adoption Intelligence.SemanticModel"
    / "definition"
    / "tables",
    ROOT
    / "value"
    / "src"
    / "Cowork Value Intelligence - Value LL.SemanticModel"
    / "definition"
    / "tables",
]
EMAIL = re.compile(r"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", re.IGNORECASE)
LOCAL_PATH = re.compile(r"[A-Z]:[\\/]Users[\\/]", re.IGNORECASE)
SECRET = re.compile(
    r"(?:client[_ -]?secret|access[_ -]?token)\s*[:=]|"
    r"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY",
    re.IGNORECASE,
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def decode_package_text(data: bytes) -> str:
    if data.startswith((b"\xff\xfe", b"\xfe\xff")):
        return data.decode("utf-16")
    if data.startswith(b"\xef\xbb\xbf"):
        return data.decode("utf-8-sig")
    decoded = data.decode("utf-8", "ignore")
    if "\x00" in decoded:
        return data.decode("utf-16-le", "ignore")
    return decoded


def validate_inventory() -> None:
    missing = [str(path.relative_to(ROOT)) for path in EXPECTED if not path.is_file()]
    require(not missing, f"Missing release files: {', '.join(missing)}")
    unexpected_pdfs = [
        str(path.relative_to(ROOT))
        for path in ROOT.rglob("*.pdf")
        if ".git" not in path.parts
    ]
    require(
        not unexpected_pdfs,
        f"PDF files require label review outside the public tree: {unexpected_pdfs}",
    )
    require(
        len(list((ROOT / "images" / "report-pages").glob("*.png"))) == 13,
        "Expected exactly 13 report-page PNG captures.",
    )
    forbidden = []
    for path in ROOT.rglob("*"):
        lowered = {part.lower() for part in path.parts}
        if ".pbi" in lowered or path.suffix.lower() in {
            ".pbix",
            ".env",
            ".key",
            ".pem",
            ".pfx",
            ".secret",
            ".token",
        }:
            forbidden.append(path)
    require(not forbidden, f"Forbidden release artifacts: {forbidden}")
    print("PASS: release inventory")


def validate_text_safety() -> None:
    failures = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or (
            path.suffix.lower() not in TEXT_SUFFIXES
            and path.name.lower() not in TEXT_FILENAMES
        ):
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if LOCAL_PATH.search(text):
            failures.append(f"{path.relative_to(ROOT)} contains a user-profile path")
        if SECRET.search(text):
            failures.append(f"{path.relative_to(ROOT)} contains a credential-like value")
        for address in EMAIL.findall(text):
            if not address.lower().endswith("@example.com"):
                failures.append(
                    f"{path.relative_to(ROOT)} contains non-example identity {address}"
                )
        if CURRENT_USERNAME and CURRENT_USERNAME in text.lower():
            failures.append(f"{path.relative_to(ROOT)} contains a local user identifier")
    require(not failures, "; ".join(failures))
    print("PASS: text privacy and credential scan")


def validate_semantic_model_invariants() -> None:
    for tables_dir in SEMANTIC_MODEL_TABLE_DIRS:
        dim_user = (tables_dir / "Dim_User.tmdl").read_text(encoding="utf-8")
        fact_thread = (tables_dir / "Fact_CoworkThread.tmdl").read_text(
            encoding="utf-8"
        )
        require(
            "else Text.Lower(Text.Trim([UserPrincipalName]))" in dim_user,
            f"{tables_dir} does not normalize enriched UPNs before model joins.",
        )
        require(
            "DistinctPluginCount = Table.Group(PerThreadPlugin" in fact_thread
            and '{"PluginCount", each Table.RowCount(_), Int64.Type}' in fact_thread,
            f"{tables_dir} does not count distinct skills per task thread.",
        )
        require(
            'each List.Sum([Plugin_Count])' not in fact_thread,
            f"{tables_dir} still treats repeated plugin invocations as distinct skills.",
        )

    value_tasks = (
        SEMANTIC_MODEL_TABLE_DIRS[2] / "Fact_Tasks.tmdl"
    ).read_text(encoding="utf-8")
    require(
        'ThreadRows = Table.SelectColumns(Fact_CoworkThread, {"ThreadId", "UserKey", "DateKey", "PrimarySkill"})'
        in value_tasks,
        "Value task totals are not sourced at task-thread grain.",
    )
    print("PASS: semantic-model identity, task-grain, and distinct-skill invariants")


def validate_markdown_links() -> None:
    missing = []
    link_pattern = re.compile(r"!?\[[^\]]*]\(([^)]+)\)")
    for path in ROOT.rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        for target in link_pattern.findall(text):
            target = target.strip().split("#", 1)[0]
            if not target or re.match(r"^(?:https?://|mailto:)", target, re.IGNORECASE):
                continue
            resolved = (path.parent / unquote(target)).resolve()
            if not resolved.exists():
                missing.append(f"{path.relative_to(ROOT)} -> {target}")
    require(not missing, f"Broken local Markdown links: {missing}")
    print("PASS: local Markdown links")


def validate_samples() -> None:
    manifest = (SAMPLE / "_VERIFY.txt").read_text(encoding="utf-8")
    manifest_hashes = dict(
        (relative, digest)
        for digest, relative in re.findall(
            r"(?m)^([0-9a-f]{64})  (.+)$",
            manifest,
        )
    )
    require(len(manifest_hashes) == 6, "Sample hash manifest must contain six files.")
    for relative, expected in manifest_hashes.items():
        path = SAMPLE / Path(relative)
        require(path.is_file(), f"Missing sample file: {relative}")
        require(sha256(path) == expected, f"Sample hash mismatch: {relative}")

    with (SAMPLE / "cowork_users.csv").open(newline="", encoding="utf-8") as handle:
        users = list(csv.DictReader(handle))
    require(len(users) == 72, "Expected 72 sample users.")
    require(
        all(row["userPrincipalName"].lower().endswith("@example.com") for row in users),
        "Every sample user must use @example.com.",
    )

    audit_files = sorted((SAMPLE / "purview_audit").glob("*.csv"))
    event_count = 0
    threads = set()
    for path in audit_files:
        with path.open(newline="", encoding="utf-8") as handle:
            for row in csv.DictReader(handle):
                event_count += 1
                require(
                    row["UserId"].lower().endswith("@example.com"),
                    f"Non-example audit identity in {path.name}.",
                )
                data = json.loads(row["AuditData"])
                event = data["CopilotEventData"]
                threads.add(event["ThreadId"])
                models = event.get("ModelTransparencyDetails", [])
                require(
                    models
                    and all(
                        item["ModelProviderName"].startswith("Synthetic Model")
                        for item in models
                    ),
                    f"Non-synthetic model label in {path.name}.",
                )
                for resource in event.get("AccessedResources", []):
                    require(
                        resource["SiteUrl"].startswith("https://tenant.example.com/"),
                        f"Non-example resource URL in {path.name}.",
                    )
    require(event_count == 3342, "Expected 3,342 audit events.")
    require(len(threads) == 900, "Expected 900 unique Cowork task threads.")

    expected_root_zip = {
        f"sample_data/{path.relative_to(SAMPLE).as_posix()}"
        for path in SAMPLE.rglob("*")
        if path.is_file()
    }
    expected_adoption_zip = {
        path.relative_to(SAMPLE).as_posix()
        for path in SAMPLE.rglob("*")
        if path.is_file()
    }
    for archive_path, expected_names, prefix in [
        (SAMPLE_ZIP, expected_root_zip, "sample_data"),
        (ADOPTION_SAMPLE_ZIP, expected_adoption_zip, None),
    ]:
        with zipfile.ZipFile(archive_path) as package:
            require(
                package.testzip() is None,
                f"{archive_path.name} failed CRC validation.",
            )
            require(
                set(package.namelist()) == expected_names,
                f"{archive_path.name} inventory mismatch.",
            )
            for info in package.infolist():
                require(
                    info.date_time == SAMPLE_ZIP_TIMESTAMP,
                    f"{archive_path.name} has a non-deterministic timestamp.",
                )
                require(
                    info.create_system == 3
                    and (info.external_attr >> 16) & 0o777 == 0o644,
                    f"{archive_path.name} has non-deterministic file attributes.",
                )
                relative = (
                    Path(info.filename).relative_to(prefix)
                    if prefix
                    else Path(info.filename)
                )
                source = SAMPLE / relative
                require(
                    package.read(info.filename) == source.read_bytes(),
                    f"{archive_path.name} content mismatch: {info.filename}",
                )
    print("PASS: sample data counts, identities, hashes, and ZIP parity")


def validate_pbit() -> None:
    for pbit in PBIT_SPECS:
        require(zipfile.is_zipfile(pbit), f"{pbit.name} is not a ZIP-based package.")
        with zipfile.ZipFile(pbit) as package:
            require(package.testzip() is None, f"{pbit.name} failed CRC validation.")
            names = package.namelist()
            require("DataModelSchema" in names, f"{pbit.name} is missing DataModelSchema.")
            require("DataModel" not in names, f"{pbit.name} contains imported model data.")
            require(
                "SecurityBindings" not in names,
                f"{pbit.name} contains machine-bound security.",
            )
            require(
                b"/SecurityBindings" not in package.read("[Content_Types].xml"),
                f"{pbit.name} declares a machine-bound security part.",
            )
            require(
                "docProps/custom.xml" in names,
                f"{pbit.name} is missing sensitivity-label metadata.",
            )
            custom_xml = package.read("docProps/custom.xml")
            custom_root = ET.fromstring(custom_xml)
            custom_properties = {
                prop.attrib["name"]: next(iter(prop)).text
                for prop in custom_root
                if "name" in prop.attrib and len(prop)
            }
            label_prefix = f"MSIP_Label_{PUBLIC_LABEL_ID}_"
            label_ids = {
                match.group(1).lower()
                for match in re.finditer(
                    r"MSIP_Label_([0-9a-f-]{36})_",
                    custom_xml.decode("utf-8"),
                    re.IGNORECASE,
                )
            }
            require(
                label_ids == {PUBLIC_LABEL_ID},
                f"{pbit.name} does not contain only the expected Public label.",
            )
            require(
                custom_properties.get(label_prefix + "Enabled", "").lower() == "true",
                f"{pbit.name} Public label is not enabled.",
            )
            require(
                custom_properties.get(label_prefix + "Name") == "Not Restricted",
                f"{pbit.name} has an unexpected Public label property name.",
            )
            require(
                custom_properties.get(label_prefix + "ContentBits") == "0",
                f"{pbit.name} Public label unexpectedly applies protection.",
            )
            combined = b"\n".join(package.read(name) for name in names)
            decoded = "\n".join(
                decode_package_text(package.read(name))
                for name in names
                if name
                in {
                    "DataModelSchema",
                    "DiagramLayout",
                    "Metadata",
                    "Report/Layout",
                    "Report/LinguisticSchema",
                    "Settings",
                    "UnappliedChanges",
                    "[Content_Types].xml",
                    "docProps/custom.xml",
                }
                or Path(name).suffix.lower() in {".json", ".xml", ".txt"}
            )
            require(
                PACKAGED_PROFILE_PATH.search(combined) is None
                and LOCAL_PATH.search(decoded) is None,
                f"{pbit.name} contains a user-profile path.",
            )
            if CURRENT_USERNAME:
                require(
                    CURRENT_USERNAME.encode("utf-8") not in combined.lower()
                    and CURRENT_USERNAME not in decoded.lower(),
                    f"{pbit.name} contains a local user ID.",
                )
            for address in EMAIL.findall(decoded):
                require(
                    address.lower().endswith("@example.com"),
                    f"{pbit.name} contains non-example identity {address}.",
                )
            require(SECRET.search(decoded) is None, f"{pbit.name} contains a secret.")
            unapplied = json.loads(decode_package_text(package.read("UnappliedChanges")))
            queries = {
                query["name"]: "\n".join(query.get("text", []))
                for query in unapplied.get("queries", [])
            }
            require(
                "else Text.Lower(Text.Trim([UserPrincipalName]))"
                in queries.get("Dim_User", ""),
                f"{pbit.name} does not normalize enriched UPNs before model joins.",
            )
            require(
                "DistinctPluginCount = Table.Group(PerThreadPlugin"
                in queries.get("Fact_CoworkThread", "")
                and 'each List.Sum([Plugin_Count])'
                not in queries.get("Fact_CoworkThread", ""),
                f"{pbit.name} does not count distinct skills per task thread.",
            )
            if pbit == PBIT_SPECS[1]:
                require(
                    "ThreadRows = Table.SelectColumns(Fact_CoworkThread"
                    in queries.get("Fact_Tasks", ""),
                    f"{pbit.name} does not value work at task-thread grain.",
                )
            parameter_names = sorted(
                query["name"]
                for query in unapplied.get("queries", [])
                if any(
                    re.search(r"IsParameterQuery\s*=\s*true", line, re.IGNORECASE)
                    for line in query.get("text", [])
                )
            )
            require(
                parameter_names == ["DataFolderPath"],
                f"{pbit.name} exposes unexpected parameter prompts: {parameter_names}.",
            )
            metadata = decode_package_text(package.read("Metadata"))
            require(
                "Contains no data." in metadata,
                f"{pbit.name} description must disclose that it contains no data.",
            )
    print("PASS: portable, data-free testing PBITs with expected label states")


def validate_release_metadata() -> None:
    releases = [
        (
            ROOT / "adoption" / "docs" / "RELEASE_VERIFICATION.json",
            "2.0.1-testing",
            PBIT_SPECS[0],
        ),
        (
            ROOT / "value" / "docs" / "RELEASE_VERIFICATION.json",
            "1.1.0-testing",
            PBIT_SPECS[1],
        ),
    ]
    for verification_path, expected_version, pbit in releases:
        verification = json.loads(verification_path.read_text(encoding="utf-8"))
        pbit_check = verification["checks"]["pbit"]
        require(
            verification["version"] == expected_version,
            f"{verification_path.relative_to(ROOT)} has a stale version.",
        )
        require(
            pbit_check["bytes"] == pbit.stat().st_size
            and pbit_check["sha256"] == sha256(pbit),
            f"{verification_path.relative_to(ROOT)} has stale PBIT metadata.",
        )
        require(
            verification["checks"]["parameters"]["promptNames"] == ["DataFolderPath"],
            f"{verification_path.relative_to(ROOT)} has stale parameter evidence.",
        )
        require(
            pbit_check["sensitivityLabelId"] == PUBLIC_LABEL_ID
            and pbit_check["sensitivityState"] == "public-labeled-and-unprotected",
            f"{verification_path.relative_to(ROOT)} has stale label evidence.",
        )

    root_verification = json.loads(
        (ROOT / "docs" / "RELEASE_VERIFICATION.json").read_text(encoding="utf-8")
    )
    require(
        root_verification["versions"]
        == {"adoption": "2.0.1-testing", "value": "1.1.0-testing"},
        "Root release verification has stale versions.",
    )
    for name, pbit in zip(("adoption", "value"), PBIT_SPECS):
        pbit_check = root_verification["checks"]["templates"][name]
        require(
            pbit_check["bytes"] == pbit.stat().st_size
            and pbit_check["sha256"] == sha256(pbit),
            f"Root release verification has stale {name} PBIT metadata.",
        )
        require(
            pbit_check["requiredPrompts"] == ["DataFolderPath"],
            f"Root release verification has stale {name} parameter evidence.",
        )
    sample_check = root_verification["checks"]["sampleData"]
    require(
        sample_check["zipBytes"] == SAMPLE_ZIP.stat().st_size
        and sample_check["zipSha256"] == sha256(SAMPLE_ZIP),
        "Root release verification has stale sample ZIP metadata.",
    )
    require(
        sample_check["adoptionZipBytes"] == ADOPTION_SAMPLE_ZIP.stat().st_size
        and sample_check["adoptionZipSha256"] == sha256(ADOPTION_SAMPLE_ZIP),
        "Root release verification has stale Adoption ZIP metadata.",
    )
    print("PASS: release verification metadata")


def validate_storyboard() -> None:
    require(zipfile.is_zipfile(PPTX), "Storyboard is not a valid PPTX package.")
    with zipfile.ZipFile(PPTX) as package:
        require(package.testzip() is None, "Storyboard PPTX failed CRC validation.")
        packaged_text = b"\n".join(
            package.read(name)
            for name in package.namelist()
            if Path(name).suffix.lower() in {".xml", ".rels", ".txt"}
        )
        require(
            PACKAGED_PROFILE_PATH.search(packaged_text) is None,
            "Storyboard PPTX contains a user-profile path.",
        )
        if CURRENT_USERNAME:
            require(
                CURRENT_USERNAME.encode("utf-8") not in packaged_text.lower(),
                "Storyboard PPTX contains a local user ID.",
            )
        require(
            b"@microsoft.com" not in packaged_text.lower(),
            "Storyboard PPTX contains a Microsoft user identity.",
        )
        require(
            b"MSIP_Label_" not in packaged_text,
            "Storyboard PPTX contains sensitivity-label metadata.",
        )
        slides = [
            name
            for name in package.namelist()
            if re.fullmatch(r"ppt/slides/slide\d+\.xml", name)
        ]
        require(len(slides) == 17, "Storyboard must contain 17 slides.")
    print("PASS: 17-slide storyboard PPTX")


def probe(path: Path) -> dict:
    executable = shutil.which("ffprobe")
    require(executable is not None, "ffprobe is required for media validation.")
    result = subprocess.run(
        [
            executable,
            "-v",
            "error",
            "-show_entries",
            "format=duration:stream=codec_name,codec_type,width,height,"
            "r_frame_rate,sample_rate,channels",
            "-of",
            "json",
            str(path),
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def validate_media() -> None:
    media = probe(VIDEO)
    streams = {stream["codec_type"]: stream for stream in media["streams"]}
    video = streams["video"]
    audio = streams["audio"]
    require(video["codec_name"] == "h264", "Walkthrough video must use H.264.")
    require((video["width"], video["height"]) == (1920, 1080), "Video must be 1080p.")
    require(video["r_frame_rate"] == "30/1", "Video must be 30 fps.")
    require(audio["codec_name"] == "aac", "Walkthrough audio must use AAC.")
    require(audio["sample_rate"] == "48000", "Audio must use 48 kHz.")
    require(audio["channels"] == 2, "Audio must be stereo.")
    duration = float(media["format"]["duration"])
    require(145 <= duration <= 165, "Walkthrough must stay close to the 2:35 reference pace.")

    srt = SUBTITLES.read_text(encoding="utf-8")
    cues = re.findall(
        r"(?ms)(\d+)\s*\n(\d{2}:\d{2}:\d{2},\d{3})\s+-->\s+"
        r"(\d{2}:\d{2}:\d{2},\d{3})\s*\n(.*?)(?=\n\n|\Z)",
        srt.replace("\r\n", "\n"),
    )
    require(cues, "SRT contains no subtitle cues.")
    previous_end = -1
    for _, start, end, _ in cues:
        start_ms = timestamp_ms(start)
        end_ms = timestamp_ms(end)
        require(start_ms > previous_end, "SRT cues overlap or are out of order.")
        require(end_ms > start_ms, "SRT cue has invalid duration.")
        previous_end = end_ms
    require(previous_end <= duration * 1000, "SRT extends beyond the walkthrough.")

    segments = json.loads(SEGMENTS.read_text(encoding="utf-8"))
    normalize_words = lambda text: re.findall(
        r"[a-z0-9]+(?:'[a-z0-9]+)?", text.lower()
    )
    subtitle_words = normalize_words(" ".join(cue[3] for cue in cues))
    narration_words = normalize_words(" ".join(segment["text"] for segment in segments))
    require(
        subtitle_words == narration_words,
        "SRT does not contain the complete approved narration.",
    )
    expected_sequence = [
        "introduction",
        "start-here",
        "activity-value",
        "actions",
        "delegation-depth",
        "value-tiers",
        "methodology",
        "leadership-payoff",
        "closing",
    ]
    require(
        [segment["id"] for segment in segments] == expected_sequence,
        "Walkthrough story sequence does not match the approved adoption-first arc.",
    )
    cost_terms = ("cost", "credit", "billing", "chargeback")
    cost_context_beats = sum(
        any(term in segment["text"].lower() for term in cost_terms)
        for segment in segments
    )
    require(
        cost_context_beats <= 1,
        "Cost or chargeback appears in more than one narration beat.",
    )
    transcript = TRANSCRIPT.read_text(encoding="utf-8")
    require(
        all(segment["text"] in transcript for segment in segments),
        "Transcript is not aligned with the approved narration.",
    )
    require(
        "template contains no embedded data" in transcript.lower()
        and "approved customer exports" in transcript.lower(),
        "Walkthrough transcript must explain the data-free customer-export model.",
    )
    timeline = json.loads(TIMELINE.read_text(encoding="utf-8"))
    require(len(timeline) == len(segments), "Timeline segment count is incorrect.")
    require(
        abs(float(timeline[-1]["endSeconds"]) - duration) < 0.1,
        "Timeline end does not match the video duration.",
    )

    preview = probe(PREVIEW)
    preview_video = preview["streams"][0]
    require(
        (preview_video["width"], preview_video["height"]) == (900, 555),
        "Preview GIF must be 900x555.",
    )
    print("PASS: 1080p adoption-first walkthrough, transcript, timeline, SRT, and preview GIF")


def timestamp_ms(value: str) -> int:
    hours, minutes, remainder = value.split(":")
    seconds, milliseconds = remainder.split(",")
    return (
        int(hours) * 3_600_000
        + int(minutes) * 60_000
        + int(seconds) * 1_000
        + int(milliseconds)
    )


def main() -> None:
    validators = [
        validate_inventory,
        validate_text_safety,
        validate_semantic_model_invariants,
        validate_markdown_links,
        validate_samples,
        validate_pbit,
        validate_release_metadata,
        validate_storyboard,
        validate_media,
    ]
    for validator in validators:
        validator()
    print(f"PASS: all {len(validators)} release validation groups")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError, zipfile.BadZipFile) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        raise SystemExit(1)

#!/usr/bin/env python3
"""Build the Cowork Value Intelligence report-page carousel GIF."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "images" / "report-pages"
OUTPUT = ROOT / "images" / "report-preview.gif"

WIDTH = 900
HEIGHT = 555
REPORT_HEIGHT = 506
HOLD_MS = 1150
TRANSITION_MS = 70
TRANSITION_FRAMES = 5

PAGES = [
    ("01-start-here.png", "Start Here"),
    ("02-executive-summary.png", "Executive Summary"),
    ("03-task-categories-methodology.png", "Task Categories & Methodology"),
    ("04-methodology-value-calculator.png", "Methodology & Value Calculator"),
    ("06-value-vs-cost.png", "Value vs Cost"),
    ("07-value-by-department.png", "Value by Department"),
    ("08-value-by-user-tier.png", "Value by User Tier"),
    ("09-right-sizing-reclaim.png", "Right-Sizing & Reclaim"),
    ("10-skills-allocated-consumption.png", "Skills & Allocated Consumption"),
    ("11-model-llm-breakdown.png", "Model & LLM Breakdown"),
    ("12-glossary.png", "Metric Glossary"),
]


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    names = ["segoeuib.ttf", "arialbd.ttf"] if bold else ["segoeui.ttf", "arial.ttf"]
    for name in names:
        candidate = Path("C:/Windows/Fonts") / name
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def build_page(file_name: str, label: str, page_number: int) -> Image.Image:
    source = Image.open(SOURCE / file_name).convert("RGB")
    report = source.resize((WIDTH, REPORT_HEIGHT), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (WIDTH, HEIGHT), "#F7F5FA")
    canvas.paste(report, (0, 0))

    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, REPORT_HEIGHT, WIDTH, HEIGHT), fill="#F7F5FA")
    draw.rectangle((0, REPORT_HEIGHT, WIDTH, REPORT_HEIGHT + 3), fill="#4B2D83")
    draw.text((20, REPORT_HEIGHT + 15), label, font=font(17, True), fill="#2B174D")
    right = "Cowork Value Intelligence"
    right_width = draw.textlength(right, font=font(13))
    draw.text(
        (WIDTH - right_width - 20, REPORT_HEIGHT + 17),
        right,
        font=font(13),
        fill="#625B6A",
    )

    dot_y = REPORT_HEIGHT + 42
    start_x = (WIDTH - (len(PAGES) * 12)) // 2
    for index in range(len(PAGES)):
        color = "#008272" if index + 1 == page_number else "#D8CEE8"
        draw.ellipse((start_x + index * 12, dot_y, start_x + index * 12 + 6, dot_y + 6), fill=color)
    return canvas


def main() -> None:
    pages = [
        build_page(file_name, label, index + 1)
        for index, (file_name, label) in enumerate(PAGES)
    ]
    frames: list[Image.Image] = []
    durations: list[int] = []

    for index, current in enumerate(pages):
        following = pages[(index + 1) % len(pages)]
        frames.append(current.quantize(colors=64, method=Image.Quantize.FASTOCTREE))
        durations.append(HOLD_MS)
        for step in range(1, TRANSITION_FRAMES + 1):
            amount = step / (TRANSITION_FRAMES + 1)
            blended = Image.blend(current, following, amount)
            frames.append(blended.quantize(colors=64, method=Image.Quantize.FASTOCTREE))
            durations.append(TRANSITION_MS)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        OUTPUT,
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=0,
        disposal=2,
        optimize=True,
    )
    print(f"{OUTPUT} ({len(frames)} frames, {WIDTH}x{HEIGHT})")


if __name__ == "__main__":
    main()

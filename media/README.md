# Walkthrough build

The walkthrough is a version-neutral executive tour of the current Cowork Value
report. It pairs each viewer-facing page with the evidence boundary needed to
interpret it safely.

## Story arc

1. Promise: observed work, transparent assumptions, and defensible decisions
2. Start with the business question
3. Read observed activity before modeled value and cost
4. Understand the work mix and its published benchmarks
5. Make value assumptions visible and challengeable
6. Keep modeled value and customer-priced cost separate
7. Interpret department and user-tier concentration with context
8. Turn right-sizing flags into human review
9. Use skill and model allocations only as directional planning evidence
10. Carry the glossary definition and evidence label with every result
11. Connect approved exports and document the next validation step

## Build

Requirements:

- Windows PowerShell or PowerShell 7
- Python 3.10+
- Pillow
- `edge-tts`
- FFmpeg and FFprobe on `PATH`

Run from the repository root:

```powershell
node .\media\build_storyboard.js
.\media\build_walkthrough.ps1
```

The storyboard build writes the version-neutral 24-slide
`Cowork Value Intelligence - Interpretation Guide.pptx`.

The walkthrough build reads `walkthrough_segments.json`, creates temporary
1920x1080 story frames, synthesizes one continuous neural narration per beat,
generates aligned subtitles, and writes:

- `Cowork-Value-Intelligence-Walkthrough.mp4`
- `Cowork-Value-Intelligence-Walkthrough.srt`
- `Cowork-Value-Intelligence-Walkthrough-transcript.md`
- `Cowork-Value-Intelligence-Walkthrough-timeline.json`

Generated frames under `media\composed` are ignored by Git.

## Release targets

- 1920x1080
- 30 fps
- H.264 video
- AAC, 48 kHz stereo audio
- approximately 4:15
- approximately -18 LUFS integrated loudness
- 0.6 second pauses between story beats
- data-free template and approved customer-export message
- no customer identity, tenant URL, or customer export
- no release or version number in narration or title frames

After rebuilding, confirm the MP4 with `ffprobe`, confirm the GIF dimensions and
frame count with Pillow, and open the generated interpretation guide in
PowerPoint to verify all 24 slides.

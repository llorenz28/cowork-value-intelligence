# Walkthrough build

The walkthrough is a 2:35 leadership story modeled on the visual rhythm of the
reference video supplied during review. It is not a page-by-page inventory.

## Story arc

1. Promise: one report for the Cowork value story
2. Start with the business decision
3. Find where adoption and value are growing
4. Understand what work people delegate
5. Measure workflow maturity and delegation depth
6. Identify champions and coaching opportunities
7. Make value assumptions visible and challengeable
8. Turn usage evidence into an enablement strategy
9. Connect approved exports and begin the customer value story

Consumption and cost appear only as supporting context in the leadership payoff.
There is no dedicated chargeback scene.

## Build

Requirements:

- Windows PowerShell or PowerShell 7
- Python 3.10+
- Pillow
- `edge-tts`
- FFmpeg and FFprobe on `PATH`

Run from the repository root:

```powershell
.\media\build_walkthrough.ps1
```

The build reads `walkthrough_segments.json`, creates temporary 1920x1080 story
frames, synthesizes one continuous neural narration per beat, generates aligned
subtitles, and writes:

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
- approximately 2:35
- approximately -18 LUFS integrated loudness
- 1.4-1.6 second pauses between story beats
- data-free template and approved customer-export message
- no customer identity, tenant URL, or customer export

Run `python .\tools\validate_release.py` after rebuilding.

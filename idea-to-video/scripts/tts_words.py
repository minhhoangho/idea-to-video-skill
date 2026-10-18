#!/usr/bin/env python3
"""Speak one scene with edge-tts and report when each word was spoken.

    tts_words.py --voice vi-VN-HoaiMyNeural --rate +0% --text "..." --out 01-hook.mp3

Writes the mp3, then prints one line on stdout: the scene's `text` and `words`
as object members (`"text": ..., "words": [...]`) that narrate.sh splices into
audioConfig.ts. Word timings come from the TTS service itself, which already
knows when it said each word, so word-synced captions need no transcription.

Called by narrate.sh with the workspace venv's python; not meant to be run by hand.
"""

import argparse
import asyncio
import json

import edge_tts


async def speak(text: str, voice: str, rate: str, out: str) -> list:
    words = []
    comm = edge_tts.Communicate(text, voice, rate=rate, boundary="WordBoundary")
    with open(out, "wb") as f:
        async for chunk in comm.stream():
            if chunk["type"] == "audio":
                f.write(chunk["data"])
            elif chunk["type"] == "WordBoundary":
                # Offsets and durations arrive in 100ns ticks.
                start = chunk["offset"] / 10_000
                words.append({
                    "text": chunk["text"],
                    "startMs": round(start),
                    "endMs": round(start + chunk["duration"] / 10_000),
                })
    return words


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--voice", required=True)
    p.add_argument("--rate", default="+0%")
    p.add_argument("--text", required=True)
    p.add_argument("--out", required=True)
    a = p.parse_args()

    words = asyncio.run(speak(a.text, a.voice, a.rate, a.out))
    # JSON is valid TypeScript, and json.dumps handles every quote and
    # backslash the script might contain. Dropping the outer braces leaves
    # members the caller can place after its own id/file/frames fields.
    print(json.dumps({"text": a.text, "words": words}, ensure_ascii=False)[1:-1])


if __name__ == "__main__":
    main()

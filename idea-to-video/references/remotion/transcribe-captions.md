# Transcribing audio for captions

**No API key is needed for this, and none should be used.** Whisper runs locally.

## When you need it

Only when you do not already have the text:

- The user supplied audio or video and wants captions from it.
- You want true word-level timestamps for karaoke-style highlighting.

On the narrated track you wrote the script and `narrate.sh` measured every clip, so the text and the timing already exist. Transcribing your own synthesised speech to recover text you have on disk is wasted time and introduces errors.

## Running it locally

```bash
scripts/setup_python_env.sh openai-whisper
.venv/bin/whisper "$JOB/project/public/audio/01-hook.mp3" \
  --model small --language vi --word_timestamps True --output_format json \
  --output_dir "$JOB/assets/captions"
```

- `--model small` is the useful floor for accuracy; `tiny` mangles proper nouns. `medium` is noticeably better and several times slower.
- `--language` explicitly — auto-detection on a short clip is unreliable, and a misdetected language produces confident nonsense.
- `--word_timestamps True` is the whole reason to do this rather than reusing the script.

The JSON gives segments and words with `start`/`end` in seconds. Multiply by `fps`.

## Cost

First run downloads the model (~500 MB for `small`). Transcription runs roughly at real time on CPU. Tell the user before starting rather than after; on a 90-second video it is a couple of minutes, not seconds.

## Accuracy

Whisper transcribes what it hears, including the wrong brand name. Diff the result against your script and keep your text where they disagree — you are after the *timings*, not the words.

# Track B — Stock footage + TTS narration

Use this track when meaning is carried by a *voice* over generic imagery: faceless storytelling, top-N lists, news recaps, motivational content, long-form-to-short repurposing. The pipeline writes a script with an LLM, fetches matching stock clips, synthesizes narration, burns subtitles, and mixes music.

MoneyPrinterTurbo (`harry0703/MoneyPrinterTurbo`) is the reference implementation. Requires macOS or Windows, `uv`, and Python 3.11. On Linux-only or terminal-less environments, fall back to Track C and hand the user the script + shot list.

## Before running

The script is the whole video on this track, so get it right before spending render time. Write the narration from the brief, show it to the user, and only proceed once approved. Read it aloud in your head against the target duration: Vietnamese narration runs roughly 3.5–4 words per second, English about 2.5–3.

## Credentials

The pipeline needs an LLM provider and a stock-footage API key (Pexels). Ask for **all missing credentials in one message**, never one at a time, and never ask for a credential the local config already has.

Environment variables the helper reads:

```
MPT_LLM_PROVIDER
MPT_LLM_API_KEY
MPT_LLM_BASE_URL
MPT_LLM_MODEL_NAME
MPT_PEXELS_API_KEY
```

Never echo these values back, never print `config.toml`, and never include a key in a command you show to the user.

## Running

Fetch the helper if only the remote skill was loaded:

```
https://raw.githubusercontent.com/harry0703/MoneyPrinterTurbo/main/docs/skill/mpt_agent.py
```

Set the terminal working directory to the helper's directory and invoke it by relative filename — absolute paths break on some Windows agent shells:

```bash
uv run --no-project --python 3.11 python mpt_agent.py --subject "<topic>"
```

Run it as one foreground command with a timeout of at least 20 minutes. Do not poll with `sleep`, `ps`, or repeated `tail` — that burns turns and tells you nothing. Extra generation options go after `--`.

Install `uv` only if the shell reports it missing:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh          # macOS
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"   # Windows
```

Do not use Docker, Conda, system pip, or the WebUI for this pipeline, do not hand-manage *its* environment, and do not run two jobs at once. Standalone Python tools are a separate matter — see the next section.

## Python environment for standalone tools

MoneyPrinterTurbo brings its own environment. Anything else you reach for does not: a narration retake with `edge-tts`, a transcript from `whisper`, a reference clip pulled with `yt-dlp`. Those go into **one venv in the user's working directory** — never system Python, never a throwaway env per job:

```bash
scripts/setup_python_env.sh              # creates ./.venv with edge-tts
scripts/setup_python_env.sh yt-dlp       # same venv, one more tool
```

The script creates `./.venv` if it is absent, reuses it if it exists, installs only what is actually missing, and adds `.venv/` to `.gitignore`. It prints the venv's `bin` directory on stdout. Pass `--dir <path>` if the user keeps environments somewhere specific.

It also checks that the interpreter can `import ssl`, and rebuilds the venv from a working interpreter when it cannot. This is not paranoia: a pyenv Python compiled against an OpenSSL that Homebrew has since retired creates a venv perfectly happily, then fails on the first download with an `ImportError` deep inside a traceback, twenty minutes into a render. Do not debug that by hand — rerun the script.

**Call tools by path, never activate.** `source .venv/bin/activate` dies with the shell that ran it, so the next command is silently back on system Python — a failure that reads like a broken install:

```bash
.venv/bin/edge-tts --voice vi-VN-NamMinhNeural --text "..." --write-media out.mp3
```

One venv serves every job in the workspace, which is the point: the user has a single directory to look at, and deleting it costs a minute to rebuild. Record any package you install beyond the default in the job's `NOTES.md`, so a re-render months later knows what the audio was built with.

## Exit handling

| Exit | Meaning | Action |
|---|---|---|
| 0 | Success — output block contains `VIDEO_FILE`, `TASK_DIR`, `LOG_FILE` | Copy `VIDEO_FILE` into the job's `out/` under the naming convention, then deliver that path. Do not re-`ls` or re-validate the source; the helper already confirmed it exists and is non-empty. |
| 10 | Missing credentials — `MPT_NEEDS_INPUT` lists exactly what is needed | Ask once for that list only, then rerun the same command with the env vars set. |
| 1 | Failure — `MPT_ERROR` plus a log path | Repair recoverable causes and retry once. If it fails again, report the failed stage, the short error, and the log path. |

If the terminal reports exit 0 but truncates the output without `MPT_RESULT`, do not assume failure — read `~/MoneyPrinterTurbo/.agent-logs/moneyprinterturbo-video/latest-result.json` once and treat `status=completed` as success.

A path-validation error from the terminal tool is not a generation failure — the helper never started. Fix the working directory and retry the relative command once. Do not cycle through path variants.

## Defaults and overrides

Upstream defaults to a Chinese 9:16 video with Pexels footage, Edge TTS, subtitles and background music. For any other output language, set the language, voice and subtitle font explicitly in the brief and pass them through — do not rely on the default.

Subtitle legibility on this track matters more than on Track A, because stock footage has unpredictable brightness. Use a heavy font with a dark plate or thick stroke, and keep captions above the platform safe area.

## Landing the output

The helper writes into its own task directory, which is not where the user's work lives. Copy the result across and record it:

```bash
cp "$VIDEO_FILE" "$JOB/out/<slug>_1080x1920_v1.mp4"
```

Keep `TASK_DIR` and `LOG_FILE` paths in the job's `NOTES.md` — when a rerun is needed weeks later, those are the only way back to what the pipeline actually did.

## Quality ceiling

Be honest with the user about what this track can and cannot do. Stock b-roll gives atmosphere, not specificity — it will never show *their* product, and clips will occasionally be only loosely related to the sentence they sit under. If the video needs to show a real screen, a real logo, or exact data, propose Track A for those beats and use stock only as connective tissue.

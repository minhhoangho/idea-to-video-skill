# Changelog

All notable changes to this skill are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

## [1.4.0] — 2026-08-28

### Added
- `input/` in every job folder — reference material the user supplies, kept
  separate from `assets/` and never written to by the agent.
- `scripts/scan_input.sh` — inventories `input/` in one table (kind, dimensions,
  duration, page count), flags images too small for the target frame and files
  that cannot be opened at all.
- `references/input-analysis.md` — what to extract from each kind of supplied
  file, how to pull a palette from an image, and the rule that every file is
  either used or declined in writing.
- `brief.md` gains a "Supplied references" section: one row per file, saying
  what was taken from it or why it was not used.

### Changed
- `new_project.sh` now runs at the end of Phase 1 instead of the start of
  Phase 4, so the Phase 2 clarification round can hand the user a real `input/`
  path. It also creates `input/` and prints a reminder to scan it.
- The clarification message gains a standing `input/` line, included even when
  the idea mentions no assets.
- Discovery slots 8 and 9 ("assets on hand", "brand constraints") now default to
  whatever is in `input/` rather than to "none".
- Phase 3 reads the supplied material before proposing directions; Phase 4
  rescans before building, and reports what a late arrival changes.

### Fixed
- The skill asked users to *describe* assets it could simply have been given.
  "What are your brand colors?" produced worse answers than a folder does, and
  supplied material had nowhere to live.

## [1.3.0] — 2026-08-27

### Added
- `scripts/setup_python_env.sh` — creates or reuses a `.venv` in the user's
  working directory, installs only the packages actually missing, and adds
  `.venv/` to `.gitignore`. Tries `uv venv`, then `uv venv --python 3.12`
  (overridable with `IDEA_TO_VIDEO_PYTHON`), then `python3 -m venv`, and
  verifies at each step that the interpreter can `import ssl` — a venv without
  working TLS cannot download anything and fails much later, confusingly.
  Refuses to overwrite a path that is not a virtualenv.
- `references/project-structure.md` documents the venv as living beside
  `video-projects/`, one environment shared by every job.

### Changed
- Track B no longer bans a hand-managed virtualenv outright. The ban now applies
  only to MoneyPrinterTurbo's own environment; standalone tools (`edge-tts`,
  `whisper`, `yt-dlp`) go into the working directory's `.venv`.
- `new_project.sh` adds `.venv/` to each job's `.gitignore`.
- `install.sh` reports whether `python3` is available.

### Fixed
- With no guidance on Python environments, the agent invented an ad-hoc venv at
  whatever path seemed convenient — outside the workspace and outside any
  convention. There is now one documented location.

## [1.2.0] — 2026-08-27

### Added
- `references/project-structure.md` — `video-projects/` workspace convention:
  one dated folder per job, versioned renders, `INDEX.md` and `NOTES.md`.
- `scripts/new_project.sh` — creates a job folder, seeds `brief.md` from the
  template, registers the job in `INDEX.md`.
- Repository packaging: install script, build script, CI validation.

### Changed
- `scaffold_remotion.sh` copies `theme.ts` into the project automatically and
  derives composition length from the beat table instead of a hardcoded value.
- Track B copies its output into the job folder under the versioned naming
  convention rather than leaving it in the pipeline's task directory.
- Track C writes its storyboard package into the job folder.
- Delivery now updates `INDEX.md` and appends to the job's `NOTES.md`.

### Fixed
- Track and QA references used `output/<name>` and `out/video.mp4`, which
  contradicted the workspace convention. All paths now route through the job
  folder.
- Scaffolded `Root.tsx` hardcoded `durationInFrames`, so editing the beat table
  silently truncated the video.
- Scaffold created a second `out/` inside the source tree, giving renders two
  plausible homes.

## [1.1.0] — 2026-08-27

### Added
- `README.md` with installation and usage.

## [1.0.0] — 2026-08-27

### Added
- Initial release: five-phase workflow (Understand, Clarify, Propose, Produce,
  Verify), three production tracks, discovery question bank, creative direction
  reference, ten motion rules, frame-inspection QA loop.

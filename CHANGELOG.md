# Changelog

All notable changes to this skill are recorded here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

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

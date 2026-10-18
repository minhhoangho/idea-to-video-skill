#!/usr/bin/env bash
# Bootstrap a Remotion project without the interactive CLI, which hangs in
# non-TTY agent shells.
#
#   ./scaffold_remotion.sh my-video 1080 1920 30
#   ./scaffold_remotion.sh my-video 1080 1920 30 video-projects/2026-08-27-my-video/project
#   ./scaffold_remotion.sh --narrated my-video 1080 1920 30 "$JOB/project"
#
# With a fifth argument it scaffolds into an existing job folder created by
# new_project.sh. Without one it falls back to ./output/<name> for quick tests.
#
# --narrated (Track B) wires Root/Main to the audioConfig.ts that narrate.sh
# generates, instead of a hand-written beat table. Safe to run before or after
# narrate.sh; an existing audioConfig.ts is never overwritten.
#
set -euo pipefail

NARRATED=0
ARGS=()
for a in "$@"; do
  case "$a" in
    --narrated) NARRATED=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
set -- ${ARGS[@]+"${ARGS[@]}"}

NAME="${1:-video}"
W="${2:-1080}"
H="${3:-1920}"
FPS="${4:-30}"
DIR="${5:-output/${NAME}}"

command -v node >/dev/null || { echo "node not found — install Node.js 18+"; exit 1; }
command -v ffmpeg >/dev/null || echo "warning: ffmpeg not found — needed for frame inspection"

# Resolve the skill root before the cd below — $0 is relative when the script is
# invoked the documented way, so anything derived from it after a cd resolves
# against the wrong directory and aborts under set -e.
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# No out/ here — renders belong in the job folder alongside brief.md, not
# nested inside the source tree.
mkdir -p "${DIR}/src/scenes" "${DIR}/src/components" "${DIR}/public/audio" "${DIR}/public/images"
cd "${DIR}"

cat > package.json <<EOF
{
  "name": "${NAME}",
  "private": true,
  "scripts": {
    "dev": "remotion studio"
  },
  "dependencies": {
    "@remotion/cli": "4.0.*",
    "@remotion/google-fonts": "4.0.*",
    "remotion": "4.0.*",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "typescript": "^5.4.0"
  }
}
EOF

cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM"],
    "jsx": "react-jsx",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true,
    "noEmit": true
  },
  "include": ["src"]
}
EOF

cat > remotion.config.ts <<'EOF'
import { Config } from '@remotion/cli/config';
Config.setVideoImageFormat('jpeg');
Config.setOverwriteOutput(true);
EOF

cat > src/index.ts <<'EOF'
import { registerRoot } from 'remotion';
import { RemotionRoot } from './Root';
registerRoot(RemotionRoot);
EOF

cat > src/Root.tsx <<EOF
import { Composition } from 'remotion';
import { Main, totalSeconds } from './Main';

export const RemotionRoot: React.FC = () => (
  <Composition
    id="Main"
    component={Main}
    durationInFrames={Math.round(totalSeconds * ${FPS})}
    fps={${FPS}}
    width={${W}}
    height={${H}}
  />
);
EOF

cat > src/Main.tsx <<'EOF'
import { AbsoluteFill, Sequence, useVideoConfig } from 'remotion';
import { colors } from './theme';

// Beat table — the single place scene timing is defined (motion rule 8).
// Root.tsx derives the composition length from this, so changing a beat
// changes the video length without a second edit anywhere else.
export const beats = [
  { name: 'hook', seconds: 2 },
  { name: 'body', seconds: 14 },
  { name: 'cta', seconds: 4 },
];

export const totalSeconds = beats.reduce((n, b) => n + b.seconds, 0);

export const Main: React.FC = () => {
  const { fps } = useVideoConfig();
  let cursor = 0;
  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      {beats.map((b) => {
        const from = cursor;
        const dur = Math.round(b.seconds * fps);
        cursor += dur;
        return (
          <Sequence key={b.name} from={from} durationInFrames={dur}>
            {/* scene component goes here */}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
EOF

# Design tokens travel with the skill — copy them in rather than making the
# agent remember to (motion rule 9 depends on this file existing). Main.tsx
# imports './theme', so a missing copy is a hard failure, not a nicety.
if [ -f "$SKILL_DIR/assets/theme.ts" ]; then
  cp "$SKILL_DIR/assets/theme.ts" src/theme.ts
  echo "copied theme.ts — fill the palette from section 6 of the brief"
else
  echo "theme.ts not found at $SKILL_DIR/assets/theme.ts — src/Main.tsx will not compile" >&2
  exit 1
fi

# The component library travels with the tokens. Scenes built from these are
# consistent with each other by construction; scenes animated from scratch in
# every file are not, and that difference is visible in the finished video.
if [ -d "$SKILL_DIR/assets/components" ]; then
  cp "$SKILL_DIR/assets/components"/*.ts "$SKILL_DIR/assets/components"/*.tsx \
     "$SKILL_DIR/assets/components/README.md" src/components/
  echo "copied components/ — see src/components/README.md for what to use when"
else
  echo "components/ not found at $SKILL_DIR/assets/components" >&2
  exit 1
fi

if [ "$NARRATED" = "1" ]; then
  cp "$SKILL_DIR/assets/narration.ts" src/narration.ts

  cat > src/Root.tsx <<EOF
import { Composition } from 'remotion';
import { FPS, TOTAL_FRAMES } from './audioConfig';
import { Main } from './Main';

// Length and fps come from the narration, never a literal. Main throws a
// readable error while there is no narration yet; max(1) only keeps the
// Composition itself valid long enough for that error to surface.
export const RemotionRoot: React.FC = () => (
  <Composition
    id="Main"
    component={Main}
    durationInFrames={Math.max(1, TOTAL_FRAMES)}
    fps={FPS}
    width={${W}}
    height={${H}}
  />
);
EOF

  cat > src/Main.tsx <<'EOF'
import { AbsoluteFill, Audio, Sequence, staticFile } from 'remotion';
import { SCENES } from './audioConfig';
import { SCENE_COMPONENTS } from './scenes';
import { colors } from './theme';

export const Main: React.FC = () => {
  if (SCENES.length === 0) {
    throw new Error('no narration yet — run scripts/narrate.sh <job> --voice <name>');
  }
  return (
    <AbsoluteFill style={{ backgroundColor: colors.bg }}>
      {SCENES.map((scene) => {
        const Component = SCENE_COMPONENTS[scene.id];
        // A missing component would render a blank sequence with the voice
        // playing over nothing, which looks like a render bug. Say what it is.
        if (!Component) {
          throw new Error(`no component for scene '${scene.id}' — add it to src/scenes/index.ts`);
        }
        return (
          <Sequence key={scene.id} from={scene.from} durationInFrames={scene.frames}>
            <Audio src={staticFile(scene.file)} />
            <Component scene={scene} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
EOF

  cat > src/scenes/index.ts <<'EOF'
import type React from 'react';
import type { NarrationScene } from '../narration';

/**
 * One entry per "## <id>" heading in script.md, keyed by the normalised id
 * narrate.sh printed (lowercase kebab-case). Each scene receives its own
 * narration — animate against scene.frames, caption with scene.words.
 */
export const SCENE_COMPONENTS: Record<string, React.FC<{ scene: NarrationScene }>> = {};
EOF

  # A placeholder so the project typechecks before narration exists. Never
  # replaces real narration — narrate.sh owns this file once it has run.
  if [ ! -f src/audioConfig.ts ]; then
    cat > src/audioConfig.ts <<EOF
// Placeholder — scripts/narrate.sh replaces this with the real timing.
import type { NarrationScene } from './narration';

export const FPS = ${FPS};
export const SCENES: NarrationScene[] = [];
export const TOTAL_FRAMES = 0;
EOF
  fi
  echo "wired Root/Main to audioConfig.ts — register scenes in src/scenes/index.ts"
fi

echo "Scaffolded ${DIR} (${W}x${H} @ ${FPS}fps)."
echo "Next: 'npm install', then build scenes in src/scenes/; render with scripts/render.sh <job>."

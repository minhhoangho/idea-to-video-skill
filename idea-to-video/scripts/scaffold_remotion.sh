#!/usr/bin/env bash
# Bootstrap a Remotion project without the interactive CLI, which hangs in
# non-TTY agent shells.
#
#   ./scaffold_remotion.sh my-video 1080 1920 30
#   ./scaffold_remotion.sh my-video 1080 1920 30 video-projects/2026-08-27-my-video/project
#
# With a fifth argument it scaffolds into an existing job folder created by
# new_project.sh. Without one it falls back to ./output/<name> for quick tests.
#
set -euo pipefail

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
    "dev": "remotion studio",
    "render": "remotion render Main ../out/${NAME}_${W}x${H}_v1.mp4 --codec=h264 --crf=18"
  },
  "dependencies": {
    "@remotion/cli": "4.0.*",
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

echo "Scaffolded ${DIR} (${W}x${H} @ ${FPS}fps)."
echo "Next: 'npm install', then build scenes in src/scenes/."

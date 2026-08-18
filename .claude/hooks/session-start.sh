#!/bin/bash
# SessionStart hook for Claude Code on the web.
#
# Ghost is an iOS app (SwiftUI/SwiftData/XCTest) built and tested exclusively
# with `xcodebuild` on macOS + Xcode — see .github/workflows/ci.yml and
# docs/DEV_ENVIRONMENT.md. Remote sessions run on Linux with no Xcode, no iOS
# SDK, and (per this environment's network policy) no way to fetch a Swift
# toolchain either, so `make build` / `make test` cannot run here. This hook
# only does what IS possible on Linux: keep the checkout consistent and catch
# config typos before they reach CI.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

SECRETS_FILE="Ghost/Resources/Config/Secrets.xcconfig"
SECRETS_TEMPLATE="Ghost/Resources/Config/Secrets.xcconfig.example"

if [ ! -f "$SECRETS_FILE" ] && [ -f "$SECRETS_TEMPLATE" ]; then
  cp "$SECRETS_TEMPLATE" "$SECRETS_FILE"
  echo "Created $SECRETS_FILE from the template (placeholder values, gitignored)."
fi

if command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" >/dev/null 2>&1; then
  if python3 -c "import yaml, sys; yaml.safe_load(open('project.yml'))" 2>/tmp/project-yml-error; then
    echo "project.yml: valid YAML."
  else
    echo "project.yml: FAILED to parse — xcodegen generate will fail in CI:"
    cat /tmp/project-yml-error
  fi
fi

cat <<'EOF'

NOTE: Ghost only builds/tests via Xcode on macOS. This session (Linux, no
Xcode, no Swift toolchain reachable) cannot run `xcodegen generate`,
`xcodebuild`, `make build`, `make test`, `make lint`, or the simulator.
Edit code here as usual; verification happens via:
  - .github/workflows/ci.yml (macOS CI, runs on every push/PR)
  - scripts/setup.sh + make build/test/lint (on a real Mac)
See docs/DEV_ENVIRONMENT.md for details.
EOF

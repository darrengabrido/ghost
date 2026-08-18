#!/usr/bin/env bash
#
# One-shot setup for a freshly cloned Ghost checkout:
#
#   1. checks Xcode and installs XcodeGen (and SwiftLint) if needed
#   2. creates Ghost/Resources/Config/Secrets.xcconfig (gitignored) from the template
#   3. generates Ghost.xcodeproj
#
# Safe to re-run: an existing Secrets.xcconfig is left alone.
#
#   scripts/setup.sh [--open]

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SECRETS_FILE="Ghost/Resources/Config/Secrets.xcconfig"
SECRETS_TEMPLATE="Ghost/Resources/Config/Secrets.xcconfig.example"
XCODEPROJ="Ghost.xcodeproj"

OPEN_XCODE=0

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'; RESET=$'\033[0m'
else
  BOLD=""; RED=""; YELLOW=""; GREEN=""; RESET=""
fi

step() { printf '\n%s==> %s%s\n' "$BOLD" "$1" "$RESET"; }
info() { printf '    %s\n' "$1"; }
ok()   { printf '    %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
warn() { printf '    %s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
die()  { printf '\n%serror:%s %s\n' "$RED" "$RESET" "$1" >&2; exit 1; }

usage() {
  cat <<'EOF'
Set up a freshly cloned Ghost checkout.

Usage: scripts/setup.sh [options]

Options:
  --open    Open Ghost.xcodeproj when setup finishes.
  -h, --help  Show this help.

Once set up, build and test from the command line with:
  make build
  make test
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --open)     OPEN_XCODE=1 ;;
    -h|--help)  usage; exit 0 ;;
    *)          usage >&2; die "Unknown option: $1" ;;
  esac
  shift
done

# ------------------------------------------------------ 1. prerequisites ----

step "Checking prerequisites"

[[ "$(uname -s)" == "Darwin" ]] || die "Ghost is an iOS app — building and testing requires macOS + Xcode.
       This checkout can still be edited anywhere, but xcodebuild only runs on a Mac
       (see docs/DEV_ENVIRONMENT.md and .github/workflows/ci.yml for the CI build)."

command -v xcodebuild >/dev/null 2>&1 || die "Xcode not found. Install Xcode 16 or newer from the App Store."

developer_dir="$(xcode-select -p 2>/dev/null || true)"
if [[ "$developer_dir" != *"/Xcode"*"/Developer"* ]]; then
  die "xcode-select points at '${developer_dir:-nothing}', not a full Xcode install.
       Fix it with: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
fi

version_output="$(xcodebuild -version 2>&1)" || die "xcodebuild failed — you may need to accept the license first:
       sudo xcodebuild -license accept
       $version_output"
ok "$(printf '%s' "$version_output" | head -n 1)"

if command -v xcodegen >/dev/null 2>&1; then
  ok "XcodeGen $(xcodegen --version 2>/dev/null | tail -n 1 | sed 's/^Version: *//')"
elif command -v brew >/dev/null 2>&1; then
  info "Installing XcodeGen…"
  brew install xcodegen
  ok "XcodeGen installed"
else
  die "XcodeGen is missing and Homebrew isn't installed.
       Install it from https://github.com/yonaskolb/XcodeGen, then re-run this script."
fi

if command -v swiftlint >/dev/null 2>&1; then
  ok "SwiftLint $(swiftlint version 2>/dev/null)"
elif command -v brew >/dev/null 2>&1; then
  info "Installing SwiftLint (optional but recommended)…"
  brew install swiftlint || warn "SwiftLint install failed — 'make lint' won't work until it's installed."
else
  warn "SwiftLint not found and Homebrew isn't installed — 'make lint' won't work until it's installed."
fi

# ------------------------------------------------------------ 2. secrets ----

step "Configuring $SECRETS_FILE"

if [[ ! -f "$SECRETS_FILE" ]]; then
  [[ -f "$SECRETS_TEMPLATE" ]] || die "Missing $SECRETS_TEMPLATE — is this a complete checkout?"
  cp "$SECRETS_TEMPLATE" "$SECRETS_FILE"
  chmod 600 "$SECRETS_FILE"
  ok "Created from the template"
  info "Edit $SECRETS_FILE and set GHOST_AI_API_KEY to a real Anthropic API key."
else
  ok "Already exists — leaving it alone"
fi

if git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$REPO_ROOT" check-ignore -q "$SECRETS_FILE" ||
    warn "$SECRETS_FILE is NOT gitignored — do not commit it."
fi

# --------------------------------------------------------- 3. project.yml ---

step "Generating $XCODEPROJ"
xcodegen generate
ok "Generated from project.yml"
info "Re-run 'xcodegen generate' (or 'make generate') after editing project.yml."

# ----------------------------------------------------------------- finish ---

step "Setup complete"
info "Next:"
info "  make build   # build for Simulator"
info "  make test    # run unit + UI tests"
info "  make lint    # run SwiftLint"
info ""
info "Build and run on a physical device for anything voice-related — the"
info "Simulator's microphone and speech recognition behavior is unreliable."

if [[ $OPEN_XCODE -eq 1 ]]; then
  open "$XCODEPROJ"
fi

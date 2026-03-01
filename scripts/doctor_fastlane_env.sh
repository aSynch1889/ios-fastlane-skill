#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"
AUTO_FIX="false"

usage() {
  cat <<USAGE
Usage:
  doctor_fastlane_env.sh [--project /abs/path] [--fix]

Checks:
  - Xcode CLI / xcodebuild
  - Ruby version (requires >= 3.1 and < 4.0)
  - Bundler availability
  - Gemfile / fastlane/Pluginfile consistency
  - bundle install status
  - fastlane validate_config (bundle exec)

Options:
  --project   Project root path (default: current dir)
  --fix       Try safe auto-fixes (bundle install, Gemfile plugin loader)
  --help      Show help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --fix) AUTO_FIX="true"; shift ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "[FAIL] project path not found: $PROJECT_DIR" >&2
  exit 1
fi

cd "$PROJECT_DIR"

ok() { echo "[PASS] $1"; }
warn() { echo "[WARN] $1"; }
fail() { echo "[FAIL] $1"; exit 1; }

if ! command -v xcode-select >/dev/null 2>&1; then
  fail "xcode-select not found. Install Xcode command line tools."
fi
ok "xcode-select: $(xcode-select -p 2>/dev/null || true)"

if ! command -v xcodebuild >/dev/null 2>&1; then
  fail "xcodebuild not found. Install Xcode."
fi
ok "xcodebuild: $(xcodebuild -version 2>/dev/null | head -n1)"

if ! command -v ruby >/dev/null 2>&1; then
  fail "ruby not found. Install Ruby 3.1~3.3 (rbenv/rvm/asdf)."
fi

RUBY_VER="$(ruby -e 'print RUBY_VERSION' 2>/dev/null || true)"
RUBY_MAJOR="$(ruby -e 'print RUBY_VERSION.split(".").first' 2>/dev/null || echo 0)"
RUBY_MINOR="$(ruby -e 'print RUBY_VERSION.split(".")[1]' 2>/dev/null || echo 0)"
ok "ruby: $(command -v ruby) ($RUBY_VER)"

if [[ "$RUBY_MAJOR" -ge 4 ]]; then
  fail "Ruby $RUBY_VER is not supported for this fastlane setup. Switch to Ruby 3.1~3.3."
fi
if [[ "$RUBY_MAJOR" -lt 3 || ( "$RUBY_MAJOR" -eq 3 && "$RUBY_MINOR" -lt 1 ) ]]; then
  fail "Ruby $RUBY_VER is too old. Use Ruby 3.1~3.3."
fi

if ! command -v bundle >/dev/null 2>&1; then
  fail "bundler not found. Install with: gem install bundler"
fi
ok "bundler: $(bundle -v 2>/dev/null || true)"

if [[ ! -f Gemfile ]]; then
  if [[ "$AUTO_FIX" == "true" ]]; then
    cat > Gemfile <<'EOF'
source "https://rubygems.org"

gem "fastlane"
EOF
    ok "created Gemfile"
  else
    fail "Gemfile missing. Run bootstrap script first, or create Gemfile."
  fi
fi

if [[ -f fastlane/Pluginfile ]]; then
  if ! grep -q 'eval_gemfile(plugins_path)' Gemfile; then
    if [[ "$AUTO_FIX" == "true" ]]; then
      cat >> Gemfile <<'EOF'

plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
EOF
      ok "patched Gemfile with Pluginfile loader"
    else
      warn "Gemfile does not load fastlane/Pluginfile (plugins may fail to load)"
      echo "      Fix: add plugins_path/eval_gemfile block to Gemfile"
    fi
  else
    ok "Gemfile plugin loader is present"
  fi
fi

if [[ "$AUTO_FIX" == "true" ]]; then
  echo "[RUN ] bundle install"
  bundle install
else
  if ! bundle check >/dev/null 2>&1; then
    warn "bundle dependencies not installed"
    echo "      Fix: bundle install"
  else
    ok "bundle dependencies are satisfied"
  fi
fi

if [[ -f fastlane/Fastfile ]]; then
  echo "[RUN ] bundle exec fastlane ios validate_config"
  FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_DISABLE_COLORS=1 CI=1 bundle exec fastlane ios validate_config
  ok "fastlane validate_config passed"
else
  warn "fastlane/Fastfile missing, skip validate_config"
fi

echo "Doctor finished."

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$SKILL_ROOT/assets/fastlane"
TARGET_DIR="$(pwd)/fastlane"
DEFAULT_TEAM_ID="YOUR_TEAM_ID"

PROJECT_NAME=""
WORKSPACE=""
XCODEPROJ=""
SCHEME_DEV=""
SCHEME_DIS=""
BUNDLE_ID_DEV=""
BUNDLE_ID_DIS=""
TEAM_ID=""
PROFILE_DEV=""
PROFILE_DIS=""
SIGNING_STYLE=""

MATCH_GIT_URL="YOUR_MATCH_GIT_URL"
MATCH_GIT_BRANCH="main"
ENABLE_QUALITY_GATE="true"
ENABLE_TESTS="true"
ENABLE_SWIFTLINT="false"
ENABLE_SLACK_NOTIFY="false"
ENABLE_WECHAT_NOTIFY="false"

DRY_RUN="false"

usage() {
  cat <<USAGE
Usage:
  bootstrap_fastlane.sh [options]

Core options:
  --project-name      MyApp
  --workspace         MyApp.xcworkspace
  --xcodeproj         MyApp.xcodeproj
  --scheme-dev        MyApp
  --scheme-dis        MyApp
  --bundle-id-dev     com.example.myapp.dev
  --bundle-id-dis     com.example.myapp
  --team-id           ABCD123456
  --profile-dev       myapp_dev
  --profile-dis       myapp_dis
  --signing-style     automatic|manual

Fastlane options:
  --match-git-url     git@github.com:org/certs.git
  --match-git-branch  main
  --enable-quality-gate true|false
  --enable-tests      true|false
  --enable-swiftlint  true|false
  --enable-slack-notify true|false
  --enable-wechat-notify true|false

Other:
  --dry-run
  --help
USAGE
}

pick_first() {
  local pattern="$1"
  local found
  found=$(find . -maxdepth 1 -name "$pattern" -print | sort | head -n1 || true)
  if [[ -n "$found" ]]; then
    basename "$found"
  fi
}

normalize_signing_style() {
  local raw="${1:-}"
  raw=$(printf "%s" "$raw" | tr '[:upper:]' '[:lower:]')
  case "$raw" in
    automatic|auto) printf "automatic" ;;
    manual) printf "manual" ;;
    *) printf "" ;;
  esac
}

normalize_bool() {
  local raw="${1:-}"
  raw=$(printf "%s" "$raw" | tr '[:upper:]' '[:lower:]')
  case "$raw" in
    true|1|yes|y) printf "true" ;;
    false|0|no|n) printf "false" ;;
    *) printf "" ;;
  esac
}

list_schemes() {
  local output=""

  if [[ -n "$WORKSPACE" && -e "$WORKSPACE" ]]; then
    output=$(xcodebuild -list -workspace "$WORKSPACE" 2>/dev/null || true)
  elif [[ -n "$XCODEPROJ" && -e "$XCODEPROJ" ]]; then
    output=$(xcodebuild -list -project "$XCODEPROJ" 2>/dev/null || true)
  fi

  printf "%s\n" "$output" | awk '
    /^[[:space:]]*Schemes:/ {in_schemes=1; next}
    in_schemes && NF==0 {exit}
    in_schemes {
      gsub(/^[[:space:]]+/, "", $0)
      if (length($0) > 0) print $0
    }
  '
}

detect_scheme() {
  local schemes=""
  local picked=""

  schemes=$(list_schemes)

  if [[ -n "$PROJECT_NAME" ]]; then
    picked=$(printf "%s\n" "$schemes" | awk -v p="$PROJECT_NAME" '$0==p {print; exit}')
  fi

  if [[ -z "$picked" ]]; then
    picked=$(printf "%s\n" "$schemes" | awk '$0 !~ /^Pods-/ {print; exit}')
  fi

  printf "%s" "$picked"
}

show_build_setting() {
  local key="$1"
  local scheme="$2"
  local output=""

  if [[ -z "$scheme" ]]; then
    return 0
  fi

  if [[ -n "$WORKSPACE" && -e "$WORKSPACE" ]]; then
    output=$(xcodebuild -showBuildSettings -workspace "$WORKSPACE" -scheme "$scheme" 2>/dev/null || true)
  elif [[ -n "$XCODEPROJ" && -e "$XCODEPROJ" ]]; then
    output=$(xcodebuild -showBuildSettings -project "$XCODEPROJ" -scheme "$scheme" 2>/dev/null || true)
  fi

  printf "%s\n" "$output" | awk -F' = ' -v k="$key" '
    $1 ~ "^[[:space:]]*"k"[[:space:]]*$" {
      v=$2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
      if (length(v) > 0 && v !~ /\$\(/) {print v; exit}
    }
  '
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-name) PROJECT_NAME="$2"; shift 2 ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --xcodeproj) XCODEPROJ="$2"; shift 2 ;;
    --scheme-dev) SCHEME_DEV="$2"; shift 2 ;;
    --scheme-dis) SCHEME_DIS="$2"; shift 2 ;;
    --bundle-id-dev) BUNDLE_ID_DEV="$2"; shift 2 ;;
    --bundle-id-dis) BUNDLE_ID_DIS="$2"; shift 2 ;;
    --team-id) TEAM_ID="$2"; shift 2 ;;
    --profile-dev) PROFILE_DEV="$2"; shift 2 ;;
    --profile-dis) PROFILE_DIS="$2"; shift 2 ;;
    --signing-style) SIGNING_STYLE="$2"; shift 2 ;;
    --match-git-url) MATCH_GIT_URL="$2"; shift 2 ;;
    --match-git-branch) MATCH_GIT_BRANCH="$2"; shift 2 ;;
    --enable-quality-gate) ENABLE_QUALITY_GATE="$2"; shift 2 ;;
    --enable-tests) ENABLE_TESTS="$2"; shift 2 ;;
    --enable-swiftlint) ENABLE_SWIFTLINT="$2"; shift 2 ;;
    --enable-slack-notify) ENABLE_SLACK_NOTIFY="$2"; shift 2 ;;
    --enable-wechat-notify) ENABLE_WECHAT_NOTIFY="$2"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    --help) usage; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$WORKSPACE" ]]; then
  WORKSPACE=$(pick_first "*.xcworkspace")
fi

if [[ -z "$XCODEPROJ" ]]; then
  XCODEPROJ=$(pick_first "*.xcodeproj")
fi

if [[ -z "$WORKSPACE" && -z "$XCODEPROJ" ]]; then
  echo "Missing project container: need .xcworkspace or .xcodeproj" >&2
  exit 1
fi

if [[ -z "$PROJECT_NAME" ]]; then
  if [[ -n "$XCODEPROJ" ]]; then
    PROJECT_NAME="${XCODEPROJ%.xcodeproj}"
  else
    PROJECT_NAME="${WORKSPACE%.xcworkspace}"
  fi
fi

if [[ -z "$SCHEME_DEV" ]]; then
  SCHEME_DEV=$(detect_scheme)
fi

if [[ -z "$SCHEME_DIS" ]]; then
  SCHEME_DIS="$SCHEME_DEV"
fi

if [[ -z "$BUNDLE_ID_DIS" ]]; then
  BUNDLE_ID_DIS=$(show_build_setting "PRODUCT_BUNDLE_IDENTIFIER" "$SCHEME_DEV")
fi

if [[ -z "$BUNDLE_ID_DEV" && -n "$BUNDLE_ID_DIS" ]]; then
  BUNDLE_ID_DEV="$BUNDLE_ID_DIS"
fi

if [[ -z "$TEAM_ID" ]]; then
  TEAM_ID=$(show_build_setting "DEVELOPMENT_TEAM" "$SCHEME_DEV")
fi

if [[ -z "$SIGNING_STYLE" ]]; then
  SIGNING_STYLE=$(show_build_setting "CODE_SIGN_STYLE" "$SCHEME_DEV")
fi
SIGNING_STYLE=$(normalize_signing_style "$SIGNING_STYLE")
if [[ -z "$SIGNING_STYLE" ]]; then
  SIGNING_STYLE="manual"
fi

ENABLE_QUALITY_GATE=$(normalize_bool "$ENABLE_QUALITY_GATE")
ENABLE_TESTS=$(normalize_bool "$ENABLE_TESTS")
ENABLE_SWIFTLINT=$(normalize_bool "$ENABLE_SWIFTLINT")
ENABLE_SLACK_NOTIFY=$(normalize_bool "$ENABLE_SLACK_NOTIFY")
ENABLE_WECHAT_NOTIFY=$(normalize_bool "$ENABLE_WECHAT_NOTIFY")

if [[ -z "$ENABLE_QUALITY_GATE" || -z "$ENABLE_TESTS" || -z "$ENABLE_SWIFTLINT" || -z "$ENABLE_SLACK_NOTIFY" || -z "$ENABLE_WECHAT_NOTIFY" ]]; then
  echo "Invalid boolean value in switches. Use true/false." >&2
  exit 1
fi

warnings=()
if [[ -z "$TEAM_ID" && "$SIGNING_STYLE" == "manual" ]]; then
  TEAM_ID="$DEFAULT_TEAM_ID"
  warnings+=("Manual signing detected but TEAM_ID was not found. Using placeholder: $DEFAULT_TEAM_ID")
elif [[ -z "$TEAM_ID" ]]; then
  warnings+=("TEAM_ID not found. Automatic signing usually works if project already has signing config.")
fi

if [[ -z "$PROFILE_DEV" && -n "$PROJECT_NAME" ]]; then
  PROFILE_DEV="$(printf "%s" "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')_dev"
fi

if [[ -z "$PROFILE_DIS" && -n "$PROJECT_NAME" ]]; then
  PROFILE_DIS="$(printf "%s" "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')_dis"
fi

required_common=(
  PROJECT_NAME SCHEME_DEV SCHEME_DIS BUNDLE_ID_DEV BUNDLE_ID_DIS SIGNING_STYLE
)

missing=()
for key in "${required_common[@]}"; do
  if [[ -z "${!key}" ]]; then
    missing+=("$key")
  fi
done

if [[ "$SIGNING_STYLE" == "manual" ]]; then
  for key in PROFILE_DEV PROFILE_DIS; do
    if [[ -z "${!key}" ]]; then
      missing+=("$key")
    fi
  done
fi

echo "Resolved config:"
echo "  PROJECT_NAME=$PROJECT_NAME"
echo "  WORKSPACE=${WORKSPACE:-<none>}"
echo "  XCODEPROJ=${XCODEPROJ:-<none>}"
echo "  SCHEME_DEV=$SCHEME_DEV"
echo "  SCHEME_DIS=$SCHEME_DIS"
echo "  BUNDLE_ID_DEV=$BUNDLE_ID_DEV"
echo "  BUNDLE_ID_DIS=$BUNDLE_ID_DIS"
echo "  TEAM_ID=${TEAM_ID:-<none>}"
echo "  SIGNING_STYLE=$SIGNING_STYLE"
echo "  PROFILE_DEV=${PROFILE_DEV:-<none>}"
echo "  PROFILE_DIS=${PROFILE_DIS:-<none>}"
echo "  MATCH_GIT_URL=$MATCH_GIT_URL"
echo "  MATCH_GIT_BRANCH=$MATCH_GIT_BRANCH"
echo "  ENABLE_QUALITY_GATE=$ENABLE_QUALITY_GATE"
echo "  ENABLE_TESTS=$ENABLE_TESTS"
echo "  ENABLE_SWIFTLINT=$ENABLE_SWIFTLINT"
echo "  ENABLE_SLACK_NOTIFY=$ENABLE_SLACK_NOTIFY"
echo "  ENABLE_WECHAT_NOTIFY=$ENABLE_WECHAT_NOTIFY"

if [[ ${#warnings[@]} -gt 0 ]]; then
  echo "Warnings:"
  for w in "${warnings[@]}"; do
    echo "  - $w"
  done
fi

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing required values: ${missing[*]}" >&2
  echo "Pass them with --<name> options." >&2
  exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run complete. No files written."
  exit 0
fi

mkdir -p "$TARGET_DIR"

render() {
  local src="$1"
  local dest="$2"

  sed \
    -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    -e "s|{{WORKSPACE}}|$WORKSPACE|g" \
    -e "s|{{XCODEPROJ}}|$XCODEPROJ|g" \
    -e "s|{{SCHEME_DEV}}|$SCHEME_DEV|g" \
    -e "s|{{SCHEME_DIS}}|$SCHEME_DIS|g" \
    -e "s|{{BUNDLE_ID_DEV}}|$BUNDLE_ID_DEV|g" \
    -e "s|{{BUNDLE_ID_DIS}}|$BUNDLE_ID_DIS|g" \
    -e "s|{{TEAM_ID}}|$TEAM_ID|g" \
    -e "s|{{PROFILE_DEV}}|$PROFILE_DEV|g" \
    -e "s|{{PROFILE_DIS}}|$PROFILE_DIS|g" \
    -e "s|{{SIGNING_STYLE}}|$SIGNING_STYLE|g" \
    -e "s|{{MATCH_GIT_URL}}|$MATCH_GIT_URL|g" \
    -e "s|{{MATCH_GIT_BRANCH}}|$MATCH_GIT_BRANCH|g" \
    -e "s|{{ENABLE_QUALITY_GATE}}|$ENABLE_QUALITY_GATE|g" \
    -e "s|{{ENABLE_TESTS}}|$ENABLE_TESTS|g" \
    -e "s|{{ENABLE_SWIFTLINT}}|$ENABLE_SWIFTLINT|g" \
    -e "s|{{ENABLE_SLACK_NOTIFY}}|$ENABLE_SLACK_NOTIFY|g" \
    -e "s|{{ENABLE_WECHAT_NOTIFY}}|$ENABLE_WECHAT_NOTIFY|g" \
    "$src" > "$dest"
}

render "$TEMPLATE_DIR/Fastfile.template" "$TARGET_DIR/Fastfile"
render "$TEMPLATE_DIR/Appfile.template" "$TARGET_DIR/Appfile"
cp "$TEMPLATE_DIR/Pluginfile.template" "$TARGET_DIR/Pluginfile"
render "$TEMPLATE_DIR/env.fastlane.example.template" "$TARGET_DIR/.env.fastlane.example"

echo "Generated: $TARGET_DIR/Fastfile"
echo "Generated: $TARGET_DIR/Appfile"
echo "Generated: $TARGET_DIR/Pluginfile"
echo "Generated: $TARGET_DIR/.env.fastlane.example"
echo "Next: bundle install && cp fastlane/.env.fastlane.example fastlane/.env.fastlane"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$SKILL_ROOT/assets/fastlane"
TARGET_DIR="$(pwd)/fastlane"
PROJECT_SCRIPTS_DIR="$(pwd)/scripts"
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
ENABLE_SNAPSHOT="false"
SNAPSHOT_SCHEME=""
SNAPSHOT_DEVICES=""
SNAPSHOT_LANGUAGES=""
METADATA_PATH="fastlane/metadata"
ENABLE_METADATA_UPLOAD="false"
ENABLE_SCREENSHOT_UPLOAD="false"
GYM_SKIP_CLEAN="false"
DERIVED_DATA_PATH=""
CI_BUNDLE_INSTALL="true"
CI_COCOAPODS_DEPLOYMENT="true"

DRY_RUN="false"
INTERACTIVE="false"
CONFIG_PATH=""

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
  --enable-snapshot   true|false
  --snapshot-scheme   AppScheme
  --snapshot-devices  "iPhone 15 Pro,iPhone 15"
  --snapshot-languages "en-US,zh-Hans"
  --metadata-path     fastlane/metadata
  --enable-metadata-upload true|false
  --enable-screenshot-upload true|false
  --gym-skip-clean    true|false
  --derived-data-path /path/to/DerivedData
  --ci-bundle-install true|false
  --ci-cocoapods-deployment true|false

Input modes:
  --config            path/to/fastlane-skill.conf
  --interactive

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

trim_spaces() {
  local v="$1"
  v="${v#${v%%[![:space:]]*}}"
  v="${v%${v##*[![:space:]]}}"
  printf "%s" "$v"
}

unquote() {
  local v="$1"
  if [[ "$v" == \"*\" && "$v" == *\" ]]; then
    v="${v:1:${#v}-2}"
  elif [[ "$v" == \'*\' && "$v" == *\' ]]; then
    v="${v:1:${#v}-2}"
  fi
  printf "%s" "$v"
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

apply_config_kv() {
  local key="$1"
  local value="$2"
  case "$key" in
    PROJECT_NAME|project_name) PROJECT_NAME="$value" ;;
    WORKSPACE|workspace) WORKSPACE="$value" ;;
    XCODEPROJ|xcodeproj) XCODEPROJ="$value" ;;
    SCHEME_DEV|scheme_dev) SCHEME_DEV="$value" ;;
    SCHEME_DIS|scheme_dis) SCHEME_DIS="$value" ;;
    BUNDLE_ID_DEV|bundle_id_dev) BUNDLE_ID_DEV="$value" ;;
    BUNDLE_ID_DIS|bundle_id_dis) BUNDLE_ID_DIS="$value" ;;
    TEAM_ID|team_id) TEAM_ID="$value" ;;
    PROFILE_DEV|profile_dev) PROFILE_DEV="$value" ;;
    PROFILE_DIS|profile_dis) PROFILE_DIS="$value" ;;
    SIGNING_STYLE|signing_style) SIGNING_STYLE="$value" ;;
    MATCH_GIT_URL|match_git_url) MATCH_GIT_URL="$value" ;;
    MATCH_GIT_BRANCH|match_git_branch) MATCH_GIT_BRANCH="$value" ;;
    ENABLE_QUALITY_GATE|enable_quality_gate) ENABLE_QUALITY_GATE="$value" ;;
    ENABLE_TESTS|enable_tests) ENABLE_TESTS="$value" ;;
    ENABLE_SWIFTLINT|enable_swiftlint) ENABLE_SWIFTLINT="$value" ;;
    ENABLE_SLACK_NOTIFY|enable_slack_notify) ENABLE_SLACK_NOTIFY="$value" ;;
    ENABLE_WECHAT_NOTIFY|enable_wechat_notify) ENABLE_WECHAT_NOTIFY="$value" ;;
    ENABLE_SNAPSHOT|enable_snapshot) ENABLE_SNAPSHOT="$value" ;;
    SNAPSHOT_SCHEME|snapshot_scheme) SNAPSHOT_SCHEME="$value" ;;
    SNAPSHOT_DEVICES|snapshot_devices) SNAPSHOT_DEVICES="$value" ;;
    SNAPSHOT_LANGUAGES|snapshot_languages) SNAPSHOT_LANGUAGES="$value" ;;
    METADATA_PATH|metadata_path) METADATA_PATH="$value" ;;
    ENABLE_METADATA_UPLOAD|enable_metadata_upload) ENABLE_METADATA_UPLOAD="$value" ;;
    ENABLE_SCREENSHOT_UPLOAD|enable_screenshot_upload) ENABLE_SCREENSHOT_UPLOAD="$value" ;;
    GYM_SKIP_CLEAN|gym_skip_clean) GYM_SKIP_CLEAN="$value" ;;
    DERIVED_DATA_PATH|derived_data_path) DERIVED_DATA_PATH="$value" ;;
    CI_BUNDLE_INSTALL|ci_bundle_install) CI_BUNDLE_INSTALL="$value" ;;
    CI_COCOAPODS_DEPLOYMENT|ci_cocoapods_deployment) CI_COCOAPODS_DEPLOYMENT="$value" ;;
    *) ;;
  esac
}

load_config_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Config file not found: $path" >&2
    exit 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(trim_spaces "$line")
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue

    if [[ "$line" != *"="* ]]; then
      continue
    fi

    local key="${line%%=*}"
    local value="${line#*=}"

    key=$(trim_spaces "$key")
    value=$(trim_spaces "$value")
    value=$(unquote "$value")

    apply_config_kv "$key" "$value"
  done < "$path"
}

prompt_with_default() {
  local prompt="$1"
  local current="$2"
  local input=""

  if [[ -n "$current" ]]; then
    read -r -p "$prompt [$current]: " input || true
  else
    read -r -p "$prompt: " input || true
  fi

  if [[ -z "$input" ]]; then
    printf "%s" "$current"
  else
    printf "%s" "$input"
  fi
}

apply_interactive_overrides() {
  PROJECT_NAME=$(prompt_with_default "Project name" "$PROJECT_NAME")
  SCHEME_DEV=$(prompt_with_default "Dev scheme" "$SCHEME_DEV")
  SCHEME_DIS=$(prompt_with_default "Dis scheme" "$SCHEME_DIS")
  BUNDLE_ID_DEV=$(prompt_with_default "Dev bundle id" "$BUNDLE_ID_DEV")
  BUNDLE_ID_DIS=$(prompt_with_default "Dis bundle id" "$BUNDLE_ID_DIS")
  SIGNING_STYLE=$(prompt_with_default "Signing style (automatic/manual)" "$SIGNING_STYLE")
  MATCH_GIT_URL=$(prompt_with_default "Match git url" "$MATCH_GIT_URL")
  ENABLE_TESTS=$(prompt_with_default "Enable tests (true/false)" "$ENABLE_TESTS")
  ENABLE_SWIFTLINT=$(prompt_with_default "Enable swiftlint (true/false)" "$ENABLE_SWIFTLINT")
  ENABLE_SNAPSHOT=$(prompt_with_default "Enable snapshot capture (true/false)" "$ENABLE_SNAPSHOT")
  ENABLE_METADATA_UPLOAD=$(prompt_with_default "Enable metadata upload (true/false)" "$ENABLE_METADATA_UPLOAD")
  ENABLE_SCREENSHOT_UPLOAD=$(prompt_with_default "Enable screenshot upload (true/false)" "$ENABLE_SCREENSHOT_UPLOAD")
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

# First pass: only extract --config to preload values.
args=("$@")
i=0
while [[ $i -lt ${#args[@]} ]]; do
  arg="${args[$i]}"
  if [[ "$arg" == "--config" ]]; then
    ((i+=1))
    [[ $i -lt ${#args[@]} ]] || { echo "--config requires a path" >&2; exit 1; }
    CONFIG_PATH="${args[$i]}"
  fi
  ((i+=1))
done

if [[ -n "$CONFIG_PATH" ]]; then
  load_config_file "$CONFIG_PATH"
fi

# Second pass: full argument parsing (cli overrides config file).
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
    --enable-snapshot) ENABLE_SNAPSHOT="$2"; shift 2 ;;
    --snapshot-scheme) SNAPSHOT_SCHEME="$2"; shift 2 ;;
    --snapshot-devices) SNAPSHOT_DEVICES="$2"; shift 2 ;;
    --snapshot-languages) SNAPSHOT_LANGUAGES="$2"; shift 2 ;;
    --metadata-path) METADATA_PATH="$2"; shift 2 ;;
    --enable-metadata-upload) ENABLE_METADATA_UPLOAD="$2"; shift 2 ;;
    --enable-screenshot-upload) ENABLE_SCREENSHOT_UPLOAD="$2"; shift 2 ;;
    --gym-skip-clean) GYM_SKIP_CLEAN="$2"; shift 2 ;;
    --derived-data-path) DERIVED_DATA_PATH="$2"; shift 2 ;;
    --ci-bundle-install) CI_BUNDLE_INSTALL="$2"; shift 2 ;;
    --ci-cocoapods-deployment) CI_COCOAPODS_DEPLOYMENT="$2"; shift 2 ;;
    --config) CONFIG_PATH="$2"; shift 2 ;;
    --interactive) INTERACTIVE="true"; shift ;;
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

if [[ "$INTERACTIVE" == "true" ]]; then
  echo "Interactive mode enabled. Press Enter to keep current values."
  apply_interactive_overrides
fi

SIGNING_STYLE=$(normalize_signing_style "$SIGNING_STYLE")
if [[ -z "$SIGNING_STYLE" ]]; then
  echo "Invalid signing style. Use automatic|manual" >&2
  exit 1
fi

ENABLE_QUALITY_GATE=$(normalize_bool "$ENABLE_QUALITY_GATE")
ENABLE_TESTS=$(normalize_bool "$ENABLE_TESTS")
ENABLE_SWIFTLINT=$(normalize_bool "$ENABLE_SWIFTLINT")
ENABLE_SLACK_NOTIFY=$(normalize_bool "$ENABLE_SLACK_NOTIFY")
ENABLE_WECHAT_NOTIFY=$(normalize_bool "$ENABLE_WECHAT_NOTIFY")
ENABLE_SNAPSHOT=$(normalize_bool "$ENABLE_SNAPSHOT")
ENABLE_METADATA_UPLOAD=$(normalize_bool "$ENABLE_METADATA_UPLOAD")
ENABLE_SCREENSHOT_UPLOAD=$(normalize_bool "$ENABLE_SCREENSHOT_UPLOAD")
GYM_SKIP_CLEAN=$(normalize_bool "$GYM_SKIP_CLEAN")
CI_BUNDLE_INSTALL=$(normalize_bool "$CI_BUNDLE_INSTALL")
CI_COCOAPODS_DEPLOYMENT=$(normalize_bool "$CI_COCOAPODS_DEPLOYMENT")

if [[ -z "$ENABLE_QUALITY_GATE" || -z "$ENABLE_TESTS" || -z "$ENABLE_SWIFTLINT" || -z "$ENABLE_SLACK_NOTIFY" || -z "$ENABLE_WECHAT_NOTIFY" || -z "$ENABLE_SNAPSHOT" || -z "$ENABLE_METADATA_UPLOAD" || -z "$ENABLE_SCREENSHOT_UPLOAD" || -z "$GYM_SKIP_CLEAN" || -z "$CI_BUNDLE_INSTALL" || -z "$CI_COCOAPODS_DEPLOYMENT" ]]; then
  echo "Invalid boolean value in switches. Use true/false." >&2
  exit 1
fi

if [[ -z "$SNAPSHOT_SCHEME" ]]; then
  SNAPSHOT_SCHEME="$SCHEME_DIS"
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
echo "  ENABLE_SNAPSHOT=$ENABLE_SNAPSHOT"
echo "  SNAPSHOT_SCHEME=$SNAPSHOT_SCHEME"
echo "  SNAPSHOT_DEVICES=${SNAPSHOT_DEVICES:-<none>}"
echo "  SNAPSHOT_LANGUAGES=${SNAPSHOT_LANGUAGES:-<none>}"
echo "  METADATA_PATH=$METADATA_PATH"
echo "  ENABLE_METADATA_UPLOAD=$ENABLE_METADATA_UPLOAD"
echo "  ENABLE_SCREENSHOT_UPLOAD=$ENABLE_SCREENSHOT_UPLOAD"
echo "  GYM_SKIP_CLEAN=$GYM_SKIP_CLEAN"
echo "  DERIVED_DATA_PATH=${DERIVED_DATA_PATH:-<none>}"
echo "  CI_BUNDLE_INSTALL=$CI_BUNDLE_INSTALL"
echo "  CI_COCOAPODS_DEPLOYMENT=$CI_COCOAPODS_DEPLOYMENT"

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

ensure_gemfile_plugin_loader() {
  local gemfile="$(pwd)/Gemfile"

  if [[ ! -f "$gemfile" ]]; then
    cat > "$gemfile" <<'EOF'
source "https://rubygems.org"

gem "fastlane"
EOF
  fi

  if ! grep -q 'eval_gemfile(plugins_path)' "$gemfile"; then
    cat >> "$gemfile" <<'EOF'

plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
EOF
  fi
}

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run complete. No files written."
  exit 0
fi

mkdir -p "$TARGET_DIR"
mkdir -p "$PROJECT_SCRIPTS_DIR"

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
    -e "s|{{ENABLE_SNAPSHOT}}|$ENABLE_SNAPSHOT|g" \
    -e "s|{{SNAPSHOT_SCHEME}}|$SNAPSHOT_SCHEME|g" \
    -e "s|{{SNAPSHOT_DEVICES}}|$SNAPSHOT_DEVICES|g" \
    -e "s|{{SNAPSHOT_LANGUAGES}}|$SNAPSHOT_LANGUAGES|g" \
    -e "s|{{METADATA_PATH}}|$METADATA_PATH|g" \
    -e "s|{{ENABLE_METADATA_UPLOAD}}|$ENABLE_METADATA_UPLOAD|g" \
    -e "s|{{ENABLE_SCREENSHOT_UPLOAD}}|$ENABLE_SCREENSHOT_UPLOAD|g" \
    -e "s|{{GYM_SKIP_CLEAN}}|$GYM_SKIP_CLEAN|g" \
    -e "s|{{DERIVED_DATA_PATH}}|$DERIVED_DATA_PATH|g" \
    -e "s|{{CI_BUNDLE_INSTALL}}|$CI_BUNDLE_INSTALL|g" \
    -e "s|{{CI_COCOAPODS_DEPLOYMENT}}|$CI_COCOAPODS_DEPLOYMENT|g" \
    "$src" > "$dest"
}

ensure_gemfile_plugin_loader

render "$TEMPLATE_DIR/Fastfile.template" "$TARGET_DIR/Fastfile"
render "$TEMPLATE_DIR/Appfile.template" "$TARGET_DIR/Appfile"
cp "$TEMPLATE_DIR/Pluginfile.template" "$TARGET_DIR/Pluginfile"
render "$TEMPLATE_DIR/env.fastlane.example.template" "$TARGET_DIR/.env.fastlane.example"
render "$TEMPLATE_DIR/env.fastlane.staging.example.template" "$TARGET_DIR/.env.fastlane.staging.example"
render "$TEMPLATE_DIR/env.fastlane.prod.example.template" "$TARGET_DIR/.env.fastlane.prod.example"
cp "$SCRIPT_DIR/doctor_fastlane_env.sh" "$PROJECT_SCRIPTS_DIR/doctor_fastlane_env.sh"
cp "$SCRIPT_DIR/fastlane_run.sh" "$PROJECT_SCRIPTS_DIR/fastlane_run.sh"
chmod +x "$PROJECT_SCRIPTS_DIR/doctor_fastlane_env.sh" "$PROJECT_SCRIPTS_DIR/fastlane_run.sh"

echo "Generated: $TARGET_DIR/Fastfile"
echo "Generated: $TARGET_DIR/Appfile"
echo "Generated: $TARGET_DIR/Pluginfile"
echo "Generated: $TARGET_DIR/.env.fastlane.example"
echo "Generated: $TARGET_DIR/.env.fastlane.staging.example"
echo "Generated: $TARGET_DIR/.env.fastlane.prod.example"
echo "Generated: $(pwd)/Gemfile"
echo "Generated: $PROJECT_SCRIPTS_DIR/doctor_fastlane_env.sh"
echo "Generated: $PROJECT_SCRIPTS_DIR/fastlane_run.sh"
echo "Next: bash scripts/doctor_fastlane_env.sh --project $(pwd) --fix"
echo "Then: copy env examples to real env files and run lanes"

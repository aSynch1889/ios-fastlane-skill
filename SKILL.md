---
name: ios-fastlane-pgyer
description: Reuse an iOS fastlane pipeline with match signing sync, quality gate (tests/lint), git-based versioning, CI lanes, Pgyer upload, TestFlight/App Store lanes, and Slack/WeChat notifications.
---

# iOS Fastlane + Pgyer (Production Ready)

Use this skill when users want to bootstrap or standardize iOS fastlane for local + CI delivery.

## Included lanes

- Build/distribute: `dev`, `dis`
- Signing sync: `certificates` (`match`)
- Quality gate: `quality_gate` (`scan` + optional `swiftlint`)
- Versioning: `versioning` (git build number + changelog)
- CI: `ci_setup`, `ci_build_dev`, `ci_build_dis`
- Release: `release_testflight`, `release_appstore`
- Validation: `validate_config`

## Workflow

1. Run bootstrap with `--dry-run` in target project root.
2. Generate files.
3. Copy `fastlane/.env.fastlane.example` to `fastlane/.env.fastlane` and fill secrets.
4. Run lanes.

## Bootstrap examples

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh --dry-run
```

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-tests true \
  --enable-swiftlint false \
  --enable-slack-notify true
```

## Release notes

- `release_testflight` and `release_appstore` use App Store Connect credentials from env (for example `APP_STORE_CONNECT_API_KEY_PATH`).
- Slack/WeChat notifications are optional and controlled by env switches.

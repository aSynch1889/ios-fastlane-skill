---
name: ios-fastlane-pgyer
description: Reuse an iOS fastlane pipeline with match signing sync, quality gate (tests/lint), git-based versioning, CI lanes, and Pgyer upload.
---

# iOS Fastlane + Pgyer (Production Ready)

Use this skill when users want to bootstrap or standardize iOS fastlane for local + CI delivery.

## What this skill now provides

- Build/distribute lanes: `dev`, `dis`
- Signing lane: `certificates` (via `match`, optional but recommended)
- Quality lane: `quality_gate` (`scan` + optional `swiftlint`)
- Versioning lane: `versioning` (git commit count + latest commit message)
- CI lanes: `ci_setup`, `ci_build_dev`, `ci_build_dis`
- Validation lane: `validate_config`

## Core workflow

1. Run bootstrap script in target iOS project root.
2. Verify detected config using `--dry-run`.
3. Generate fastlane files.
4. Copy `fastlane/.env.fastlane.example` to `fastlane/.env.fastlane` and fill real secrets.
5. Run lanes as needed.

## Bootstrap command

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh --dry-run
```

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-tests true \
  --enable-swiftlint false
```

## Fastlane usage examples

```bash
bundle exec fastlane ios validate_config
bundle exec fastlane ios quality_gate
bundle exec fastlane ios dev
bundle exec fastlane ios dis
bundle exec fastlane ios ci_build_dev
```

## Notes

- If `SIGNING_STYLE=manual` and `MATCH_GIT_URL` is configured, `certificates` will sync signing assets with `match`.
- If `TEAM_ID` is missing in manual mode, script writes `YOUR_TEAM_ID` placeholder and warns, without blocking generation.
- `dis` lane defaults to `ad-hoc`; adjust export method when needed.

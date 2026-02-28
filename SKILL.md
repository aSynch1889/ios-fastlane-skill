---
name: ios-fastlane-skill
description: Reuse an iOS fastlane pipeline with match signing sync, profiles lane, quality gate, git/tag versioning, CI lanes, multi-environment staging/prod lanes, changelog + artifact manifest output, release lanes, and Slack/WeChat notifications.
---

# iOS Fastlane Skill (Production Ready)

## Included lanes

- Build/distribute: `dev`, `dis`, `staging`, `prod`
- Signing: `certificates`, `profiles`
- Quality/version: `quality_gate`, `versioning`
- CI: `ci_setup`, `ci_build_dev`, `ci_build_dis`
- Release: `release_testflight`, `release_appstore`
- Validation: `validate_config`

## Hooks and output

- Hooks: `before_all`, `after_all`, `error`
- Changelog markdown: `fastlane/builds/CHANGELOG_<env>_<version>_<build>.md`
- Artifact manifest: `fastlane/builds/ARTIFACT_MANIFEST_<lane>_<timestamp>.json`

## Bootstrap modes

- Standard: `--dry-run` then generate
- Config file: `--config path/to/fastlane-skill.conf`
- Interactive: `--interactive`

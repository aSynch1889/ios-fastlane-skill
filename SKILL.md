---
name: ios-fastlane-skill
description: Reuse an iOS fastlane pipeline with match signing sync, quality gate (tests/lint), git-based versioning, CI lanes, multi-environment staging/prod lanes, changelog markdown generation, Pgyer/TestFlight/App Store release, and Slack/WeChat notifications.
---

# iOS Fastlane Skill (Production Ready)

## Included lanes

- Build/distribute: `dev`, `dis`, `staging`, `prod`
- Signing sync: `certificates` (`match`)
- Quality gate: `quality_gate` (`scan` + optional `swiftlint`)
- Versioning: `versioning` (git build number + changelog)
- CI: `ci_setup`, `ci_build_dev`, `ci_build_dis`
- Release: `release_testflight`, `release_appstore`
- Validation: `validate_config`

## Environment files

Generated examples:
- `fastlane/.env.fastlane.example`
- `fastlane/.env.fastlane.staging.example`
- `fastlane/.env.fastlane.prod.example`

Runtime files:
- `fastlane/.env.fastlane`
- `fastlane/.env.fastlane.staging`
- `fastlane/.env.fastlane.prod`

`staging` and `prod` lanes automatically load their env layer file.

## Changelog output

Every build generates markdown changelog under:
- `fastlane/builds/CHANGELOG_<env>_<version>_<build>.md`

The changelog filename is included in Slack/WeChat notification text.

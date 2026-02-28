# Trigger And Usage Examples

This document shows how to trigger `ios-fastlane-skill` and use its generated fastlane capabilities.

## Trigger examples

```text
请使用 $ios-fastlane-skill，帮我在当前 iOS 项目初始化 fastlane。
```

```text
Use $ios-fastlane-skill to bootstrap fastlane in this iOS project.
```

## Bootstrap examples

Dry-run:

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --dry-run
```

Config file mode:

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --config ./fastlane-skill.conf
```

Interactive mode:

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --interactive
```

## Usage examples

```bash
bundle exec fastlane ios validate_config
bundle exec fastlane ios profiles
bundle exec fastlane ios dev
bundle exec fastlane ios dis
bundle exec fastlane ios staging
bundle exec fastlane ios prod
bundle exec fastlane ios ci_build_dev
bundle exec fastlane ios release_testflight
bundle exec fastlane ios release_appstore
```

## Output files

- `fastlane/builds/*.ipa`
- `fastlane/builds/CHANGELOG_<env>_<version>_<build>.md`
- `fastlane/builds/ARTIFACT_MANIFEST_<lane>_<timestamp>.json`

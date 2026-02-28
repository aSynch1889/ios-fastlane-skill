# Trigger And Usage Examples

This document shows how to trigger `ios-fastlane-skill` and use its generated fastlane capabilities.

## 1. How to trigger the skill

### Chinese prompts

```text
请使用 $ios-fastlane-skill，帮我在当前 iOS 项目初始化 fastlane。
```

```text
用 ios-fastlane-skill 这个技能，按当前工程自动探测参数并生成 fastlane 配置。
```

### English prompts

```text
Use $ios-fastlane-skill to bootstrap fastlane in this iOS project.
```

```text
Use ios-fastlane-skill and auto-detect project settings, then generate fastlane files.
```

## 2. Bootstrap command examples

Preview detected settings:

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --dry-run
```

Generate with optional overrides:

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-tests true \
  --enable-swiftlint false \
  --enable-slack-notify true
```

## 3. First run after generation

```bash
bundle install
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
cp fastlane/.env.fastlane.staging.example fastlane/.env.fastlane.staging
cp fastlane/.env.fastlane.prod.example fastlane/.env.fastlane.prod
bundle exec fastlane ios validate_config
```

## 4. Lane usage examples

Build and distribute:

```bash
bundle exec fastlane ios dev
bundle exec fastlane ios dis
```

Multi-environment:

```bash
bundle exec fastlane ios staging
bundle exec fastlane ios prod
```

CI lanes:

```bash
bundle exec fastlane ios ci_build_dev
bundle exec fastlane ios ci_build_dis
```

Release lanes:

```bash
bundle exec fastlane ios release_testflight
bundle exec fastlane ios release_appstore
```

## 5. Output artifacts

After a build, check:

- `fastlane/builds/*.ipa`
- `fastlane/builds/CHANGELOG_<env>_<version>_<build>.md`

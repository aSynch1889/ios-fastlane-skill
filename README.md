# iOS Fastlane Pgyer Skill

English | [中文](#中文说明)

A reusable Codex skill to bootstrap and standardize iOS fastlane with signing sync, quality gates, git-based versioning, CI lanes, Pgyer upload, TestFlight/App Store release, and channel notifications.

## Features

- Generates:
  - `fastlane/Fastfile`
  - `fastlane/Appfile`
  - `fastlane/Pluginfile`
  - `fastlane/.env.fastlane.example`
- Supports `.xcworkspace` and `.xcodeproj`
- Auto-detects scheme, bundle id, signing style, team id (optional)
- Lanes included:
  - `prepare`, `quality_gate`, `versioning`, `certificates`
  - `dev`, `dis`
  - `ci_setup`, `ci_build_dev`, `ci_build_dis`
  - `release_testflight`, `release_appstore`
  - `validate_config`, `clean_builds`
- Optional notifications:
  - Slack webhook
  - WeChat webhook

## Quick Start

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

```bash
bundle install
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
# fill secrets in .env.fastlane
bundle exec fastlane ios validate_config
bundle exec fastlane ios dev
```

## Release Examples

```bash
bundle exec fastlane ios release_testflight
bundle exec fastlane ios release_appstore
```

## Important Env Keys

```text
PGYER_API_KEY
MATCH_GIT_URL
MATCH_GIT_BRANCH
MATCH_PASSWORD

ENABLE_QUALITY_GATE
ENABLE_TESTS
ENABLE_SWIFTLINT

ENABLE_SLACK_NOTIFY
SLACK_WEBHOOK_URL
ENABLE_WECHAT_NOTIFY
WECHAT_WEBHOOK_URL

APP_STORE_CONNECT_API_KEY_PATH
TESTFLIGHT_GROUPS
```

## Script Parameters

```text
--project-name
--workspace
--xcodeproj
--scheme-dev
--scheme-dis
--bundle-id-dev
--bundle-id-dis
--team-id
--profile-dev
--profile-dis
--signing-style automatic|manual
--match-git-url
--match-git-branch
--enable-quality-gate true|false
--enable-tests true|false
--enable-swiftlint true|false
--enable-slack-notify true|false
--enable-wechat-notify true|false
--dry-run
```

---

## 中文说明

这是一个可复用的 Codex skill，用于在 iOS 项目中快速搭建并标准化 fastlane 流程，覆盖签名同步、质量门禁、版本策略、CI 构建、蒲公英分发、TestFlight/App Store 发布，以及通知通道。

### 能力

- 自动生成：
  - `fastlane/Fastfile`
  - `fastlane/Appfile`
  - `fastlane/Pluginfile`
  - `fastlane/.env.fastlane.example`
- 支持 `.xcworkspace` / `.xcodeproj`
- 自动探测 scheme、bundle id、签名模式、team id（可选）
- 内置 lanes：
  - `prepare`、`quality_gate`、`versioning`、`certificates`
  - `dev`、`dis`
  - `ci_setup`、`ci_build_dev`、`ci_build_dis`
  - `release_testflight`、`release_appstore`
  - `validate_config`、`clean_builds`
- 可选通知：
  - Slack webhook
  - 企业微信 webhook

### 快速开始

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

```bash
bundle install
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
# 填写 .env.fastlane 中的密钥
bundle exec fastlane ios validate_config
bundle exec fastlane ios dev
```

### 发布示例

```bash
bundle exec fastlane ios release_testflight
bundle exec fastlane ios release_appstore
```

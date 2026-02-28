# iOS Fastlane Skill

English | [中文](#中文说明)

A reusable Codex skill to bootstrap and standardize iOS fastlane with match signing, quality gates, CI lanes, multi-environment lanes, release lanes, changelog/manifest outputs, and notifications.

## Features

- Generates:
  - `fastlane/Fastfile`
  - `fastlane/Appfile`
  - `fastlane/Pluginfile`
  - `fastlane/.env.fastlane.example`
  - `fastlane/.env.fastlane.staging.example`
  - `fastlane/.env.fastlane.prod.example`
- Lanes:
  - `prepare`, `quality_gate`, `versioning`, `certificates`, `profiles`
  - `dev`, `dis`, `staging`, `prod`
  - `ci_setup`, `ci_build_dev`, `ci_build_dis`
  - `release_testflight`, `release_appstore`
  - `validate_config`, `clean_builds`
- Hooks and observability:
  - `before_all` / `after_all` / `error`
  - Changelog markdown: `fastlane/builds/CHANGELOG_<env>_<version>_<build>.md`
  - Artifact manifest: `fastlane/builds/ARTIFACT_MANIFEST_<lane>_<timestamp>.json`
- Notifications:
  - Slack webhook
  - WeChat webhook

## Quick Start

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --dry-run
```

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-tests true \
  --enable-swiftlint false \
  --enable-slack-notify true
```

```bash
bundle install
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
cp fastlane/.env.fastlane.staging.example fastlane/.env.fastlane.staging
cp fastlane/.env.fastlane.prod.example fastlane/.env.fastlane.prod
bundle exec fastlane ios validate_config
bundle exec fastlane ios dev
```

## Config And Interactive Modes

Use config file (key=value):

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --config ./fastlane-skill.conf
```

Use interactive wizard mode:

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --interactive
```

## Examples

```bash
bundle exec fastlane ios profiles
bundle exec fastlane ios ci_build_dev
bundle exec fastlane ios staging
bundle exec fastlane ios release_testflight
bundle exec fastlane ios release_appstore
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
--gym-skip-clean true|false
--derived-data-path /path
--ci-bundle-install true|false
--ci-cocoapods-deployment true|false
--config path
--interactive
--dry-run
```

---

## 中文说明

这是一个可复用的 Codex skill，用于标准化 iOS fastlane：签名管理、质量门禁、CI、多环境、发布渠道、通知与构建产物可观测。

### 主要能力

- 自动生成 fastlane 关键文件与 `.env.*` 示例
- 内置 lanes：`dev/dis/staging/prod`、`ci_build_*`、`release_*`、`profiles`
- 内置 hooks：`before_all` / `after_all` / `error`
- 自动输出：
  - `CHANGELOG_*.md`
  - `ARTIFACT_MANIFEST_*.json`
- 支持 Slack/企业微信通知
- bootstrap 支持 `--interactive` 与 `--config`

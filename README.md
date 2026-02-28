# iOS Fastlane Pgyer Skill

English | [中文](#中文说明)

A reusable Codex skill to bootstrap and standardize iOS fastlane with signing sync, quality gates, git-based versioning, CI lanes, and Pgyer upload.

## Features

- Generates:
  - `fastlane/Fastfile`
  - `fastlane/Appfile`
  - `fastlane/Pluginfile`
  - `fastlane/.env.fastlane.example`
- Supports both `.xcworkspace` and `.xcodeproj`
- Auto-detects project settings:
  - project/workspace
  - scheme (prefers project name)
  - bundle identifiers
  - signing style (`automatic` / `manual`)
  - team id (optional)
- Advanced lanes included:
  - `certificates` (match)
  - `quality_gate` (scan + optional swiftlint)
  - `versioning` (git-driven build/changelog)
  - `ci_setup`, `ci_build_dev`, `ci_build_dis`
  - `validate_config`

## Repository Structure

```text
SKILL.md
agents/openai.yaml
assets/fastlane/Fastfile.template
assets/fastlane/Appfile.template
assets/fastlane/Pluginfile.template
assets/fastlane/env.fastlane.example.template
scripts/bootstrap_fastlane.sh
```

## Quick Start

Run in your iOS project root:

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh --dry-run
```

Generate files:

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-tests true \
  --enable-swiftlint false
```

Then:

```bash
bundle install
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
# fill PGYER_API_KEY / MATCH_PASSWORD / etc
bundle exec fastlane ios validate_config
bundle exec fastlane ios dev
```

## Main Lanes

```text
prepare
quality_gate
versioning
certificates
dev
dis
ci_setup
ci_build_dev
ci_build_dis
validate_config
clean_builds
```

## Signing Strategy

- `automatic`
  - No profile required
  - `match` lane is skipped
- `manual`
  - Requires profiles
  - If `MATCH_GIT_URL` is set, `certificates` syncs signing assets via `match`
  - Missing team id falls back to `YOUR_TEAM_ID` placeholder with warning

## Key Script Parameters

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
--dry-run
```

## CI Example

```bash
bundle exec fastlane ios ci_build_dev
bundle exec fastlane ios ci_build_dis
```

---

## 中文说明

这是一个可复用的 Codex skill，用于在 iOS 项目中快速搭建并标准化 fastlane 流程，覆盖签名同步、质量门禁、版本策略、CI 构建与蒲公英分发。

### 功能

- 自动生成：
  - `fastlane/Fastfile`
  - `fastlane/Appfile`
  - `fastlane/Pluginfile`
  - `fastlane/.env.fastlane.example`
- 支持 `.xcworkspace` / `.xcodeproj`
- 自动探测工程参数：
  - 工程容器
  - scheme（优先项目同名）
  - bundle id
  - 签名模式（`automatic` / `manual`）
  - team id（可选）
- 内置高级 lane：
  - `certificates`（match）
  - `quality_gate`（scan + 可选 swiftlint）
  - `versioning`（基于 git 的 build/changelog）
  - `ci_setup`、`ci_build_dev`、`ci_build_dis`
  - `validate_config`

### 快速开始

在 iOS 项目根目录先预览：

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh --dry-run
```

生成配置：

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-tests true \
  --enable-swiftlint false
```

然后执行：

```bash
bundle install
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
# 填写 PGYER_API_KEY / MATCH_PASSWORD 等
bundle exec fastlane ios validate_config
bundle exec fastlane ios dev
```

### 签名策略

- `automatic`
  - 不要求 profile
  - `certificates` 自动跳过
- `manual`
  - 要求 profile
  - 配置 `MATCH_GIT_URL` 后可通过 `certificates` 同步签名资产
  - team id 缺失时写入 `YOUR_TEAM_ID` 占位并提醒

### 常用 lane

```text
prepare
quality_gate
versioning
certificates
dev
dis
ci_setup
ci_build_dev
ci_build_dis
validate_config
clean_builds
```

### 脚本参数

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
--dry-run
```

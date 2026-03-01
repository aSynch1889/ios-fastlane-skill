# iOS Fastlane Skill

English | [中文](#中文说明)

A reusable Codex skill to bootstrap and standardize iOS fastlane with match signing, quality gates, CI lanes, multi-environment lanes, release lanes, changelog/manifest outputs, screenshot+metadata pipeline, and channel notifications.

## Overview

This skill targets production-grade iOS delivery workflows where teams need:

- Consistent fastlane structure across multiple projects
- Stable signing behavior in local and CI environments
- Multi-channel release support (Pgyer, TestFlight, App Store)
- Better observability (duration, artifact summary, changelog, failure context)

It generates templates and scripts so teams can focus on project-specific config instead of rewriting lanes.

## Features

- Generates:
  - `fastlane/Fastfile`
  - `fastlane/Appfile`
  - `fastlane/Pluginfile`
  - `fastlane/.env.fastlane.example`
  - `fastlane/.env.fastlane.staging.example`
  - `fastlane/.env.fastlane.prod.example`
  - `scripts/doctor_fastlane_env.sh`
  - `scripts/fastlane_run.sh`
- Supports `.xcworkspace` and `.xcodeproj`
- Normalizes project paths in generated `Fastfile` (resolved from project root), so lanes work even when fastlane runs from `fastlane/`
- Auto-detects key project fields during bootstrap
- Lanes:
  - Base: `prepare`, `quality_gate`, `versioning`, `validate_config`, `clean_builds`
  - Signing: `certificates`, `profiles`
  - Build/Distribute: `dev`, `dis`, `staging`, `prod`
  - CI: `ci_setup`, `ci_build_dev`, `ci_build_dis`
  - Release: `snapshot_capture`, `metadata_sync`, `release_testflight`, `release_appstore`
- Hooks and observability:
  - `before_all` / `after_all` / `error`
  - Changelog markdown: `fastlane/builds/CHANGELOG_<env>_<version>_<build>.md`
  - Artifact manifest: `fastlane/builds/ARTIFACT_MANIFEST_<lane>_<timestamp>.json`
- Notifications:
  - Slack webhook
  - WeChat webhook

## Prerequisites

- macOS + Xcode CLI tools (`xcodebuild` in PATH)
- Ruby 3.1~3.3 + Bundler (Ruby 4.x not recommended for this fastlane setup)
- iOS project with `.xcodeproj` or `.xcworkspace`

Optional but recommended:

- `match` certificate repo + `MATCH_PASSWORD`
- App Store Connect API key file (`.p8`) for release lanes

## Quick Start

### 1. Preview auto-detected config

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --dry-run
```

### 2. Generate templates

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-tests true \
  --enable-swiftlint false \
  --enable-slack-notify true
```

### 3. Prepare env files

```bash
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
cp fastlane/.env.fastlane.staging.example fastlane/.env.fastlane.staging
cp fastlane/.env.fastlane.prod.example fastlane/.env.fastlane.prod
```

`bootstrap_fastlane.sh` also writes project-local helper scripts under `scripts/`:

- `scripts/doctor_fastlane_env.sh` for preflight checks and optional auto-fixes
- `scripts/fastlane_run.sh` for one-command doctor + lane run

### 4. Install and validate

```bash
bash scripts/doctor_fastlane_env.sh --project "$(pwd)" --fix
```

### 5. One-command run (recommended)

```bash
bash scripts/fastlane_run.sh --project "$(pwd)" --lane dev
```

## Bootstrap Modes

### Mode A: Standard CLI options

Use command-line arguments for direct setup.

### Mode B: Config file

Create a `fastlane-skill.conf` (key=value), then run:

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --config ./fastlane-skill.conf
```

### Mode C: Interactive wizard

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --interactive
```

## Path Resolution Behavior

- `WORKSPACE` / `XCODEPROJ` are resolved to absolute paths from project root in generated `Fastfile`.
- `OUTPUT_DIR` is resolved to `fastlane/builds` under the current project.
- `METADATA_PATH` is resolved from project root (unless explicitly overridden with an absolute env value).

This avoids common failures like:
`Neither WORKSPACE nor XCODEPROJ exists. Please check generated config.`

## Common Lane Examples

### Signing

```bash
bundle exec fastlane ios certificates
bundle exec fastlane ios profiles
```

### Build and distribute

```bash
bundle exec fastlane ios dev
bundle exec fastlane ios dis
bundle exec fastlane ios staging
bundle exec fastlane ios prod
```

### CI

```bash
bundle exec fastlane ios ci_setup
bundle exec fastlane ios ci_build_dev
bundle exec fastlane ios ci_build_dis
```

### Screenshot + metadata pipeline

```bash
bundle exec fastlane ios snapshot_capture
bundle exec fastlane ios metadata_sync
```

### Release channels

```bash
bundle exec fastlane ios release_testflight
bundle exec fastlane ios release_appstore
```

## Important Env Keys

### Distribution and signing

| Key | Required | Purpose | Example |
|---|---|---|---|
| `PGYER_API_KEY` | Yes (if uploading to Pgyer) | API key for `dev/dis/staging/prod` Pgyer upload | `abc123...` |
| `PGYER_APP_URL` | No | App page URL used in notifications | `https://www.pgyer.com/your_app` |
| `MATCH_GIT_URL` | Recommended (manual signing/CI) | Certificate/profile repo for `match` | `git@github.com:org/certs.git` |
| `MATCH_GIT_BRANCH` | No | `match` branch | `main` |
| `MATCH_PASSWORD` | Required if `match` encrypted repo is used | Decryption password for `match` repo | `your-password` |

### Quality gate and notifications

| Key | Required | Purpose | Example |
|---|---|---|---|
| `ENABLE_QUALITY_GATE` | No | Master switch for quality checks | `true` |
| `ENABLE_TESTS` | No | Run `scan` tests before build | `true` |
| `ENABLE_SWIFTLINT` | No | Run `swiftlint` if installed | `false` |
| `ENABLE_SLACK_NOTIFY` | No | Enable Slack notifications | `true` |
| `SLACK_WEBHOOK_URL` | Required when Slack enabled | Slack incoming webhook | `https://hooks.slack.com/...` |
| `ENABLE_WECHAT_NOTIFY` | No | Enable WeChat bot notifications | `false` |
| `WECHAT_WEBHOOK_URL` | Required when WeChat enabled | WeChat robot webhook | `https://qyapi.weixin.qq.com/...` |

### App Store / screenshot / metadata

| Key | Required | Purpose | Example |
|---|---|---|---|
| `APP_STORE_CONNECT_API_KEY_PATH` | Required for TestFlight/App Store lanes | Path to ASC API key `.p8` | `/abs/path/AuthKey_XXXX.p8` |
| `TESTFLIGHT_GROUPS` | No | Comma-separated TestFlight groups | `Internal,QA` |
| `ENABLE_SNAPSHOT` | No | Enable `snapshot_capture` lane | `true` |
| `SNAPSHOT_SCHEME` | No | Scheme for snapshot run | `MyApp` |
| `SNAPSHOT_DEVICES` | No | Comma-separated iOS devices | `iPhone 15 Pro,iPhone 15` |
| `SNAPSHOT_LANGUAGES` | No | Comma-separated locales | `en-US,zh-Hans` |
| `METADATA_PATH` | Required for metadata/screenshots upload | Metadata root for deliver | `fastlane/metadata` |
| `ENABLE_METADATA_UPLOAD` | No | Upload metadata in release | `true` |
| `ENABLE_SCREENSHOT_UPLOAD` | No | Upload screenshots in release | `true` |

### Performance and CI

| Key | Required | Purpose | Example |
|---|---|---|---|
| `GYM_SKIP_CLEAN` | No | Skip clean to speed up builds | `true` |
| `DERIVED_DATA_PATH` | No | Reuse derived data directory | `/tmp/DerivedData` |
| `CI_BUNDLE_INSTALL` | No | Run `bundle install` in `ci_setup` | `true` |
| `CI_COCOAPODS_DEPLOYMENT` | No | Use pods deployment mode in CI | `true` |
| `ENABLE_ARTIFACT_MANIFEST` | No | Emit artifact manifest JSON | `true` |

## Script Parameters

| Parameter | Required | Description | Example |
|---|---|---|---|
| `--project-name` | No (auto-detect) | Project name used in template and output naming | `MyApp` |
| `--workspace` | No (auto-detect) | Xcode workspace path | `MyApp.xcworkspace` |
| `--xcodeproj` | No (auto-detect) | Xcode project path | `MyApp.xcodeproj` |
| `--scheme-dev` | No (auto-detect) | Scheme for dev lane | `MyApp-Dev` |
| `--scheme-dis` | No (auto-detect) | Scheme for dis/release lanes | `MyApp` |
| `--bundle-id-dev` | No (auto-detect) | Bundle ID used by dev lane | `com.example.myapp.dev` |
| `--bundle-id-dis` | No (auto-detect) | Bundle ID used by dis/release lanes | `com.example.myapp` |
| `--team-id` | No | Apple Team ID (manual signing strongly recommended) | `ABCD123456` |
| `--profile-dev` | Required in manual signing (if not derivable) | Provisioning profile name for dev | `myapp_dev` |
| `--profile-dis` | Required in manual signing (if not derivable) | Provisioning profile name for dis | `myapp_dis` |
| `--signing-style` | No | Signing mode | `automatic` or `manual` |
| `--match-git-url` | No | Match repo URL | `git@github.com:org/certs.git` |
| `--match-git-branch` | No | Match repo branch | `main` |
| `--enable-quality-gate` | No | Enable quality gate lane checks | `true` |
| `--enable-tests` | No | Enable scan tests | `true` |
| `--enable-swiftlint` | No | Enable swiftlint check | `false` |
| `--enable-slack-notify` | No | Enable Slack notify switch | `true` |
| `--enable-wechat-notify` | No | Enable WeChat notify switch | `false` |
| `--enable-snapshot` | No | Enable snapshot pipeline | `true` |
| `--snapshot-scheme` | No | Snapshot run scheme | `MyApp` |
| `--snapshot-devices` | No | Snapshot devices list | `"iPhone 15 Pro,iPhone 15"` |
| `--snapshot-languages` | No | Snapshot locales list | `"en-US,zh-Hans"` |
| `--metadata-path` | No | Metadata directory for deliver | `fastlane/metadata` |
| `--enable-metadata-upload` | No | Upload metadata in release_appstore | `true` |
| `--enable-screenshot-upload` | No | Upload screenshots in release_appstore | `true` |
| `--gym-skip-clean` | No | Skip clean before gym | `true` |
| `--derived-data-path` | No | Derived data path for caching | `/tmp/DerivedData` |
| `--ci-bundle-install` | No | Install gems in `ci_setup` | `true` |
| `--ci-cocoapods-deployment` | No | Enable pods deployment mode in CI | `true` |
| `--config` | No | Read key=value config file | `./fastlane-skill.conf` |
| `--interactive` | No | Ask interactively for key values | flag |
| `--dry-run` | No | Print resolved config without writing files | flag |

## Outputs and Observability

After build/release lanes, check:

- IPA files in `fastlane/builds/`
- Changelog markdown in `fastlane/builds/CHANGELOG_*.md`
- Artifact manifests in `fastlane/builds/ARTIFACT_MANIFEST_*.json`

Notification messages include lane/status/version/build/commit and summary fields such as duration and ipa size.

## Notes

- In manual signing mode, configure profiles/team/match carefully.
- For App Store release, ensure metadata path and App Store Connect auth are valid.
- For screenshot pipeline, configure devices/languages explicitly for deterministic outputs.
- If build lanes fail with signing errors (for example missing `iOS Development` certificate), that is an environment/codesigning setup issue rather than a template-generation issue.

---

## 中文说明

这是一个可复用的 Codex skill，用于在 iOS 项目中快速搭建并标准化 fastlane 流程，覆盖签名管理、质量门禁、CI、多环境发布、截图与元数据、发布渠道以及构建可观测。

## 总览

这个 skill 适用于“要长期维护发布链路”的团队场景，目标是解决：

- 多项目 fastlane 结构不一致，迁移和维护成本高
- 本地和 CI 签名行为不稳定，容易出现证书/描述文件问题
- 发布渠道割裂，无法统一到蒲公英/TestFlight/App Store
- 构建结果不可观测，失败排查成本高

通过模板和脚本，把通用能力固化，项目侧只维护配置。

## 功能清单

- 自动生成：
  - `fastlane/Fastfile`
  - `fastlane/Appfile`
  - `fastlane/Pluginfile`
  - `fastlane/.env.fastlane.example`
  - `fastlane/.env.fastlane.staging.example`
  - `fastlane/.env.fastlane.prod.example`
- 支持 `.xcworkspace` / `.xcodeproj`
- 初始化时自动识别核心工程参数
- 内置 lanes：
  - 基础：`prepare`、`quality_gate`、`versioning`、`validate_config`、`clean_builds`
  - 签名：`certificates`、`profiles`
  - 构建分发：`dev`、`dis`、`staging`、`prod`
  - CI：`ci_setup`、`ci_build_dev`、`ci_build_dis`
  - 发布：`snapshot_capture`、`metadata_sync`、`release_testflight`、`release_appstore`
- 内置 hooks 与可观测：
  - `before_all` / `after_all` / `error`
  - 变更文档：`fastlane/builds/CHANGELOG_<env>_<version>_<build>.md`
  - 产物清单：`fastlane/builds/ARTIFACT_MANIFEST_<lane>_<timestamp>.json`
- 通知通道：
  - Slack webhook
  - 企业微信 webhook

## 前置要求

- macOS + Xcode 命令行工具（PATH 内可用 `xcodebuild`）
- Ruby 3.1~3.3 + Bundler（不建议 Ruby 4.x）
- iOS 工程（`.xcodeproj` 或 `.xcworkspace`）

可选但推荐：

- `match` 证书仓库 + `MATCH_PASSWORD`
- App Store Connect API Key（`.p8`）

## 快速开始

### 1. 先预览自动探测结果

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --dry-run
```

### 2. 生成模板

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-tests true \
  --enable-swiftlint false \
  --enable-slack-notify true
```

### 3. 准备环境文件

```bash
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
cp fastlane/.env.fastlane.staging.example fastlane/.env.fastlane.staging
cp fastlane/.env.fastlane.prod.example fastlane/.env.fastlane.prod
```

### 4. 安装并校验

```bash
bash scripts/doctor_fastlane_env.sh --project "$(pwd)" --fix
```

### 5. 一键执行（推荐）

```bash
bash scripts/fastlane_run.sh --project "$(pwd)" --lane dev
```

## 初始化模式

### 模式 A：命令行参数模式

直接在命令中传参，适合一次性初始化。

### 模式 B：配置文件模式

先写 `fastlane-skill.conf`（`key=value`），再执行：

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --config ./fastlane-skill.conf
```

### 模式 C：交互向导模式

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --interactive
```

## 路径解析行为

- 生成的 `Fastfile` 会把 `WORKSPACE` / `XCODEPROJ` 按项目根目录解析为绝对路径。
- `OUTPUT_DIR` 固定解析到当前项目的 `fastlane/builds`。
- `METADATA_PATH` 按项目根目录解析（除非你在环境变量里显式传入绝对路径）。

这样可以避免常见错误：
`Neither WORKSPACE nor XCODEPROJ exists. Please check generated config.`

## 常见 Lane 用法

### 签名相关

```bash
bundle exec fastlane ios certificates
bundle exec fastlane ios profiles
```

### 构建与分发

```bash
bundle exec fastlane ios dev
bundle exec fastlane ios dis
bundle exec fastlane ios staging
bundle exec fastlane ios prod
```

### CI 场景

```bash
bundle exec fastlane ios ci_setup
bundle exec fastlane ios ci_build_dev
bundle exec fastlane ios ci_build_dis
```

### 截图与元数据流水线

```bash
bundle exec fastlane ios snapshot_capture
bundle exec fastlane ios metadata_sync
```

### 发布渠道

```bash
bundle exec fastlane ios release_testflight
bundle exec fastlane ios release_appstore
```

## 关键环境变量

### 分发与签名

| 变量 | 是否必填 | 作用 | 示例 |
|---|---|---|---|
| `PGYER_API_KEY` | 是（需要上传蒲公英时） | `dev/dis/staging/prod` 上传蒲公英所需密钥 | `abc123...` |
| `PGYER_APP_URL` | 否 | 通知里附带的蒲公英下载页链接 | `https://www.pgyer.com/your_app` |
| `MATCH_GIT_URL` | 建议配置（manual/CI） | `match` 证书仓库地址 | `git@github.com:org/certs.git` |
| `MATCH_GIT_BRANCH` | 否 | `match` 使用的分支 | `main` |
| `MATCH_PASSWORD` | 使用加密 match 仓库时必填 | `match` 仓库解密密码 | `your-password` |

### 质量门禁与通知

| 变量 | 是否必填 | 作用 | 示例 |
|---|---|---|---|
| `ENABLE_QUALITY_GATE` | 否 | 质量门禁总开关 | `true` |
| `ENABLE_TESTS` | 否 | 构建前执行 `scan` 测试 | `true` |
| `ENABLE_SWIFTLINT` | 否 | 构建前执行 `swiftlint` | `false` |
| `ENABLE_SLACK_NOTIFY` | 否 | 开启 Slack 通知 | `true` |
| `SLACK_WEBHOOK_URL` | 开启 Slack 时必填 | Slack Incoming Webhook 地址 | `https://hooks.slack.com/...` |
| `ENABLE_WECHAT_NOTIFY` | 否 | 开启企业微信通知 | `false` |
| `WECHAT_WEBHOOK_URL` | 开启企业微信时必填 | 企业微信机器人 Webhook 地址 | `https://qyapi.weixin.qq.com/...` |

### App Store / 截图 / 元数据

| 变量 | 是否必填 | 作用 | 示例 |
|---|---|---|---|
| `APP_STORE_CONNECT_API_KEY_PATH` | TestFlight/App Store 发布必填 | App Store Connect API Key (`.p8`) 路径 | `/abs/path/AuthKey_XXXX.p8` |
| `TESTFLIGHT_GROUPS` | 否 | TestFlight 测试组（逗号分隔） | `Internal,QA` |
| `ENABLE_SNAPSHOT` | 否 | 开启 `snapshot_capture` 截图流程 | `true` |
| `SNAPSHOT_SCHEME` | 否 | 截图使用的 Scheme | `MyApp` |
| `SNAPSHOT_DEVICES` | 否 | 截图设备列表（逗号分隔） | `iPhone 15 Pro,iPhone 15` |
| `SNAPSHOT_LANGUAGES` | 否 | 截图语言列表（逗号分隔） | `en-US,zh-Hans` |
| `METADATA_PATH` | 上传 metadata/screenshots 时必填 | deliver metadata 根目录 | `fastlane/metadata` |
| `ENABLE_METADATA_UPLOAD` | 否 | `release_appstore` 是否上传 metadata | `true` |
| `ENABLE_SCREENSHOT_UPLOAD` | 否 | `release_appstore` 是否上传截图 | `true` |

### 性能与 CI

| 变量 | 是否必填 | 作用 | 示例 |
|---|---|---|---|
| `GYM_SKIP_CLEAN` | 否 | 构建前跳过 clean，加快速度 | `true` |
| `DERIVED_DATA_PATH` | 否 | DerivedData 目录（用于缓存复用） | `/tmp/DerivedData` |
| `CI_BUNDLE_INSTALL` | 否 | `ci_setup` 是否执行 `bundle install` | `true` |
| `CI_COCOAPODS_DEPLOYMENT` | 否 | CI 中是否启用 pods deployment 模式 | `true` |
| `ENABLE_ARTIFACT_MANIFEST` | 否 | 是否输出构建产物清单 JSON | `true` |

## 脚本参数

| 参数 | 是否必填 | 说明 | 示例 |
|---|---|---|---|
| `--project-name` | 否（自动识别） | 项目名，用于模板变量与产物命名 | `MyApp` |
| `--workspace` | 否（自动识别） | Xcode workspace 路径 | `MyApp.xcworkspace` |
| `--xcodeproj` | 否（自动识别） | Xcode project 路径 | `MyApp.xcodeproj` |
| `--scheme-dev` | 否（自动识别） | `dev` lane 使用的 Scheme | `MyApp-Dev` |
| `--scheme-dis` | 否（自动识别） | `dis/release` lane 使用的 Scheme | `MyApp` |
| `--bundle-id-dev` | 否（自动识别） | `dev` lane 使用的 Bundle ID | `com.example.myapp.dev` |
| `--bundle-id-dis` | 否（自动识别） | `dis/release` lane 使用的 Bundle ID | `com.example.myapp` |
| `--team-id` | 否 | Apple Team ID（manual signing 建议配置） | `ABCD123456` |
| `--profile-dev` | manual 签名下需可推导或显式提供 | dev 描述文件名 | `myapp_dev` |
| `--profile-dis` | manual 签名下需可推导或显式提供 | dis 描述文件名 | `myapp_dis` |
| `--signing-style` | 否 | 签名模式 | `automatic` / `manual` |
| `--match-git-url` | 否 | `match` 证书仓库地址 | `git@github.com:org/certs.git` |
| `--match-git-branch` | 否 | `match` 分支 | `main` |
| `--enable-quality-gate` | 否 | 是否启用质量门禁 | `true` |
| `--enable-tests` | 否 | 是否执行 `scan` 测试 | `true` |
| `--enable-swiftlint` | 否 | 是否执行 `swiftlint` | `false` |
| `--enable-slack-notify` | 否 | 是否开启 Slack 通知 | `true` |
| `--enable-wechat-notify` | 否 | 是否开启企业微信通知 | `false` |
| `--enable-snapshot` | 否 | 是否启用截图流水线 | `true` |
| `--snapshot-scheme` | 否 | 截图使用的 Scheme | `MyApp` |
| `--snapshot-devices` | 否 | 截图设备列表（逗号分隔） | `"iPhone 15 Pro,iPhone 15"` |
| `--snapshot-languages` | 否 | 截图语言列表（逗号分隔） | `"en-US,zh-Hans"` |
| `--metadata-path` | 否 | metadata 目录 | `fastlane/metadata` |
| `--enable-metadata-upload` | 否 | 发布时是否上传 metadata | `true` |
| `--enable-screenshot-upload` | 否 | 发布时是否上传 screenshots | `true` |
| `--gym-skip-clean` | 否 | 是否跳过 clean | `true` |
| `--derived-data-path` | 否 | DerivedData 路径（缓存） | `/tmp/DerivedData` |
| `--ci-bundle-install` | 否 | CI 中是否执行 `bundle install` | `true` |
| `--ci-cocoapods-deployment` | 否 | CI 是否启用 pods deployment 模式 | `true` |
| `--config` | 否 | 加载 `key=value` 配置文件 | `./fastlane-skill.conf` |
| `--interactive` | 否 | 进入交互式参数输入 | 标记参数 |
| `--dry-run` | 否 | 仅输出解析结果，不写文件 | 标记参数 |

## 产物与可观测

构建后可在 `fastlane/builds/` 查看：

- IPA 包
- `CHANGELOG_*.md`（变更说明）
- `ARTIFACT_MANIFEST_*.json`（产物清单）

通知内容默认包含 lane/status/version/build/commit，以及耗时、包体积等摘要。

## 说明

- 手动签名模式下请确保 profile/team/match 配置正确。
- App Store 发布前请确认 metadata 路径和 App Store Connect 鉴权文件有效。
- 截图流水线建议固定 devices/languages，保证输出稳定。
- 如果构建类 lane 报证书缺失（例如缺少 `iOS Development` 证书），这通常是本机签名环境问题，不是模板生成问题。

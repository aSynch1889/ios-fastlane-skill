---
name: ios-fastlane-pgyer
description: 复用 iOS Fastlane 打包与蒲公英上传流程。用于在新 iOS 项目快速生成 prepare/dev/dis/clean_builds lane，并包含构建失败通知与 pgyer 上传。
---

# iOS Fastlane + Pgyer

当用户希望在 iOS 项目中快速复用 Fastlane 打包（Dev/Dis）并上传蒲公英时使用此技能。

## 自动探测策略

脚本会优先自动读取：
- `WORKSPACE`（当前目录第一个 `.xcworkspace`，可为空）
- `XCODEPROJ`（当前目录第一个 `.xcodeproj`，可为空）
- 要求二选一存在：`workspace` 或 `project`
- `PROJECT_NAME`（优先由 `xcodeproj` 推导）
- `SCHEME_DEV`（优先项目同名 scheme）
- `SCHEME_DIS`（默认等于 `SCHEME_DEV`）
- `BUNDLE_ID_DEV` / `BUNDLE_ID_DIS`（`PRODUCT_BUNDLE_IDENTIFIER`）
- `TEAM_ID`（`DEVELOPMENT_TEAM`，可为空）
- `SIGNING_STYLE`（`CODE_SIGN_STYLE`，自动归一化为 `automatic` 或 `manual`）
- `PROFILE_DEV` / `PROFILE_DIS`（默认 `<project>_dev` / `<project>_dis`）

其中签名规则：
- `automatic`：不强制要求 `team-id` 和 profile
- `manual`：要求 `profile-dev` 和 `profile-dis`；`team-id` 缺失时会填 `YOUR_TEAM_ID` 并提醒后续配置

## 执行命令

先预览：

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh --dry-run
```

再生成（只传需要覆盖的值）：

```bash
bash /Users/newdroid/.codex/skills/ios-fastlane-pgyer/scripts/bootstrap_fastlane.sh \
  --signing-style "automatic"
```

## 常见覆盖场景

- 只有 `.xcodeproj`：不用传 `--workspace`
- 强制手动签名：`--signing-style manual --profile-dev xxx --profile-dis xxx`
- 强制自动签名：`--signing-style automatic`
- 显式指定 team：`--team-id ABCD123456`

## 验证命令

- `bundle exec fastlane ios prepare`
- `bundle exec fastlane ios dev`
- `bundle exec fastlane ios dis`

## 约束

- 模板默认 iOS 平台。
- `Fastfile` 包含本地 macOS 通知（`osascript`）。
- `dis` lane 默认 `ad-hoc` 导出，如需 `app-store`/`enterprise` 需在生成后调整 `export_method` 与 `export_options`。

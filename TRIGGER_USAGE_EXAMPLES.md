# iOS Fastlane Skill 触发与使用示例（中文详细版）

本文档用于演示：在 Codex 中如何触发 `ios-fastlane-skill`，触发后如何在项目里使用已经生成的 fastlane 能力。

## 1. 适用前提

- 你的工程目录下有 iOS 工程（`.xcworkspace` 或 `.xcodeproj`）。
- 已安装 Ruby 3.1~3.3 + Bundler（用于执行 `bundle exec fastlane`，不建议 Ruby 4.x）。
- 已将 skill 安装到本机：`${CODEX_HOME}/skills/ios-fastlane-skill`（跨机器推荐使用 `$CODEX_HOME`，不要写死用户目录）。

## 2. 在 Codex 中触发 Skill 的方式

下面几种写法都可以触发，推荐第一种。

### 2.1 显式触发（推荐）

```text
请使用 $ios-fastlane-skill，帮我初始化当前项目的 fastlane，先 dry-run 再正式生成。
```

### 2.2 自然语言触发

```text
使用 ios-fastlane-skill，为当前 iOS 项目生成可用于 CI、蒲公英和 TestFlight 的 fastlane 配置。
```

### 2.3 带约束触发（指定签名和质量门禁）

```text
请用 $ios-fastlane-skill 初始化，签名用 manual，开启 tests，关闭 swiftlint，并给我 staging/prod 两套环境。
```

## 3. 初始化操作（触发后在项目中执行）

## 3.1 第一步：dry-run 查看自动识别结果

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --dry-run
```

重点确认这些识别项是否正确：

- `PROJECT_NAME`
- `WORKSPACE` / `XCODEPROJ`
- `SCHEME_DEV` / `SCHEME_DIS`
- `BUNDLE_ID_DEV` / `BUNDLE_ID_DIS`
- `SIGNING_STYLE`
- `TEAM_ID`（manual 下若缺失会给默认占位并提醒）

说明：生成的 `Fastfile` 会将 `WORKSPACE` / `XCODEPROJ` 按项目根目录解析成绝对路径，避免相对路径导致的构建失败。

## 3.2 第二步：正式生成 fastlane 目录与模板

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --signing-style manual \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-tests true \
  --enable-swiftlint false \
  --enable-slack-notify true \
  --enable-wechat-notify false
```

## 3.3 第三步：准备环境变量文件

```bash
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
cp fastlane/.env.fastlane.staging.example fastlane/.env.fastlane.staging
cp fastlane/.env.fastlane.prod.example fastlane/.env.fastlane.prod
```

至少优先配置这些键：

- `PGYER_API_KEY`
- `MATCH_PASSWORD`（若使用 match）
- `APP_STORE_CONNECT_API_KEY_PATH`（TestFlight / App Store 必需）
- `SLACK_WEBHOOK_URL` / `WECHAT_WEBHOOK_URL`（如启用通知）

## 3.4 第四步：安装依赖并校验

```bash
bash scripts/doctor_fastlane_env.sh --project "$(pwd)" --fix
```

## 4. 常见触发指令模板（可直接复制到 Codex）

## 4.1 快速接入蒲公英

```text
请使用 $ios-fastlane-skill，按自动签名初始化，并给我最小可用的 dev/dis + 蒲公英上传配置。
```

## 4.2 团队标准化（match + CI）

```text
请使用 $ios-fastlane-skill，按 manual + match 初始化，生成 ci_setup、ci_build_dev、ci_build_dis，并默认 readonly signing。
```

## 4.3 完整发布链路（Pgyer + TestFlight + App Store）

```text
使用 $ios-fastlane-skill，帮我生成 staging/prod、多渠道发布和通知能力，并加上 quality gate。
```

## 4.4 补齐截图与元数据能力

```text
请在当前 fastlane 配置上，用 $ios-fastlane-skill 增加 snapshot_capture 和 metadata_sync，并给出 release_appstore 示例。
```

## 5. 触发后如何使用 Lane（按场景）

## 5.1 配置检查与准备

```bash
bundle exec fastlane ios prepare
bundle exec fastlane ios validate_config
bundle exec fastlane ios quality_gate
bundle exec fastlane ios versioning
```

## 5.2 本地测试分发（蒲公英）

```bash
bundle exec fastlane ios dev
bundle exec fastlane ios dis
```

## 5.3 多环境发布

```bash
bundle exec fastlane ios staging
bundle exec fastlane ios prod
```

## 5.4 签名与描述文件标准化

```bash
bundle exec fastlane ios certificates
bundle exec fastlane ios profiles
```

## 5.5 CI 专用

```bash
bundle exec fastlane ios ci_setup
bundle exec fastlane ios ci_build_dev
bundle exec fastlane ios ci_build_dis
```

## 5.6 Apple 渠道发布

```bash
bundle exec fastlane ios release_testflight
bundle exec fastlane ios release_appstore
```

## 5.7 截图与元数据

```bash
bundle exec fastlane ios snapshot_capture
bundle exec fastlane ios metadata_sync
```

## 5.8 清理构建产物

```bash
bundle exec fastlane ios clean_builds
```

## 6. 三种典型落地流程

## 6.1 最小可用流程（新项目）

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh --dry-run
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh
cp fastlane/.env.fastlane.example fastlane/.env.fastlane
bash scripts/doctor_fastlane_env.sh --project "$(pwd)" --fix
bash scripts/fastlane_run.sh --project "$(pwd)" --lane dev
```

## 6.2 团队协作流程（推荐）

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --signing-style manual \
  --match-git-url "git@github.com:your-org/certificates.git" \
  --enable-quality-gate true \
  --enable-tests true
bash scripts/doctor_fastlane_env.sh --project "$(pwd)" --fix
bash scripts/fastlane_run.sh --project "$(pwd)" --lane ci_setup
bash scripts/fastlane_run.sh --project "$(pwd)" --lane ci_build_dis
```

## 6.3 商店发布流程

```bash
bash scripts/doctor_fastlane_env.sh --project "$(pwd)" --fix
bash scripts/fastlane_run.sh --project "$(pwd)" --lane snapshot_capture
bash scripts/fastlane_run.sh --project "$(pwd)" --lane metadata_sync
bash scripts/fastlane_run.sh --project "$(pwd)" --lane release_testflight
bash scripts/fastlane_run.sh --project "$(pwd)" --lane release_appstore
```

## 7. 参数传递优先级

初始化脚本参数优先级如下：

1. 命令行参数（最高）
2. `--config` 指定的配置文件
3. 脚本自动探测值
4. 默认值

示例：

```bash
bash ${CODEX_HOME}/skills/ios-fastlane-skill/scripts/bootstrap_fastlane.sh \
  --config ./fastlane-skill.conf \
  --scheme-dev "MyApp-Debug"
```

上例中 `SCHEME_DEV` 最终以 `--scheme-dev` 为准。

## 8. 常见问题

## 8.1 没有 workspace 只有 project 可以吗

可以。脚本会自动识别 `.xcodeproj` 并正常生成配置。

## 8.2 manual 签名缺少 team id 会阻塞吗

不会。会先使用占位值并提醒你后续补齐，便于先打通流程。

## 8.3 自动签名是否需要 team id

建议配置。多数场景下自动签名也依赖 Team 归属来稳定解析签名身份。

## 8.4 如何确认 lane 是否已经生成完整

执行：

```bash
bundle exec fastlane lanes | rg "prepare|quality_gate|versioning|dev|dis|staging|prod|release_testflight|snapshot_capture|metadata_sync|release_appstore|ci_setup|ci_build_dev|ci_build_dis|validate_config|clean_builds"
```

能看到上述 lane 即表示生成完成。

## 8.5 `Neither WORKSPACE nor XCODEPROJ exists` 怎么处理

先重新执行 bootstrap，确认当前使用的是最新模板；新模板会自动做路径归一化。如果仍报错，请检查 `Fastfile` 里 `WORKSPACE` / `XCODEPROJ` 是否是可访问的绝对路径。

## 8.6 `No signing certificate "iOS Development" found` 是什么问题

这是本机签名环境问题（证书/私钥/Team 配置），不是模板生成问题。按 codesigning 流程补齐证书、私钥或切换到可用签名方式后再重试。

## 9. 建议发布到博客时的结构

- 第一部分：为什么要用 skill（痛点 + 目标）
- 第二部分：如何触发（3 条指令模板）
- 第三部分：10 分钟跑通（最小流程命令）
- 第四部分：团队化落地（match + CI + quality gate）
- 第五部分：商店发布与截图元数据（TestFlight + App Store）

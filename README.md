# Echoes

拍下此刻的表情，按表情或按时间回看。

前置相机拍照 → 检测人脸 → 识别表情 → 归档。

底部是自绘的 tab 栏：左侧按表情归档、右侧按时间归档，**中间嵌一颗大的液态玻璃
圆钮**作为拍照键。三者在同一条玻璃底栏里，不存在悬浮、遮挡或"两个按钮"的问题。

## 环境要求

| 项 | 版本 |
|---|---|
| Xcode | **27.0** 或更高（本项目用 27.0 / 27A266a 验证） |
| iOS SDK | **iPhoneOS 27.0** |
| 部署目标 | **iOS 27.0** |
| Swift | 6.4（语言模式 5.0） |

> 工程里 `IPHONEOS_DEPLOYMENT_TARGET` 与 SDK 版本是绑定的。SDK 27.1 发布后
> 把 `project.pbxproj` 里那 4 处 `27.0` 改为 `27.1` 即可，代码不需要动。

## 构建与测试

```bash
# 真机架构编译
xcodebuild -project Echoes.xcodeproj -scheme Echoes \
  -sdk iphoneos -destination 'generic/platform=iOS' build

# 模拟器编译并跑测试
xcodebuild -project Echoes.xcodeproj -scheme Echoes \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0' test
```

首次跑测试前需要建一个 iOS 27.0 的模拟器（该 runtime 默认没有设备）：

```bash
xcrun simctl create "iPhone 17 Pro" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro \
  com.apple.CoreSimulator.SimRuntime.iOS-27-0
```

### 在模拟器上检查界面

模拟器没有相机，会自动改用包内采样图跑通整条识别管线。DEBUG 下有两个启动参数
可以在不点屏幕的情况下（`simctl` 无法模拟点击）检查两个归档页：

```bash
xcrun simctl launch <device> com.Echoesone.Echoes \
  -uiSeedSampleData -uiStartSection timeline
```

- `-uiSeedSampleData`：灌入 5 条示例记录，时间跨越今天/昨天/本月/更早
- `-uiStartSection emotions|timeline`：直接打开指定的归档 tab
- `-uiShowSettings`：直接打开设置页

这些参数只在 DEBUG 编译里存在。

## 语言

界面以**英文为源语言**，同时提供简体中文，可在「设置 → 语言」里随时切换，
**立即生效、不需要重启**。

实现要点：

- 文案集中在 `Echoes/Localizable.xcstrings`（String Catalog），键是稳定标识符
  （`settings.cache.clear`）而不是英文原文，改英文措辞不会破坏已有翻译。
- 所有取值都走 `L10n`（`Echoes/Domain/L10n.swift`），英文写死在代码里作为兜底，
  即使某个键漏了翻译也只会退化成英文，不会显示成 `settings.cache.clear`。
- 切换语言靠**自己定位对应的 `.lproj` bundle**（`LanguageManager`），
  而不是改 `AppleLanguages` —— 后者必须重启才生效。
- 切换时 `EchoesApp` 换掉根视图的 `id` 重建整棵视图树，因为 SwiftUI 不会
  因为字符串表变了就重新求值已经算过的 `Text`。
- 日期与数字格式也跟着界面语言走（`DateFormatters` 按语言缓存 formatter）。

新增语言只需：加一个 `<lang>.lproj` / 在 `Localizable.xcstrings` 里补一列，
再把语言加进 `AppLanguage`。

## 目录结构

```
Echoes/
  Domain/      纯数据类型：Emotion、Memory、AppInfo、L10n、语言管理、时间分组算法
  Storage/     磁盘：MemoryStore、ImageStore、MemoryManifest、MemoryMigrator、缩略图缓存
  Capture/     相机与流程编排：CameraController、CaptureCoordinator
  Analysis/    识别：EmotionAnalyzer（Vision + CoreML）、EmotionReport
  Design/      字体、格式化、通用控件
  views/       界面
Localizable.xcstrings   中英文文案（String Catalog）
EchoesTests/   Swift Testing 测试套件
```

## 数据存放

```
<App 沙盒>/Documents/Echoes/
  memories.json          归档清单（ISO8601 日期，原子写）
  Images/<uuid>.jpg      原图，长边 ≤ 2048
  Thumbnails/<uuid>.jpg  缩略图，长边 ≤ 600
```

清单里只存**文件名**，不存绝对路径 —— 沙盒路径在重装或恢复备份后会变，
存绝对路径必然失效（这是旧版本的一个 bug）。

### 从旧版本迁移

旧版本的数据布局是 `Documents/memories.json` + 散落在 `Documents/` 根目录的图片，
清单里存的是 `cover` 绝对路径。App 首次启动时会自动迁移：

1. 旧清单解码（兼容 `date` / `cover` 字段与大小写不一的 `emotion`）
2. 旧图片按新规范重新落盘并生成缩略图
3. 旧文件**改名保留**为 `*.migrated`，不删除

迁移失败时旧数据原封不动，界面会提示原因。清单损坏时会把原文件备份为
`memories.corrupt-<时间戳>.json` 再以空归档启动，不会静默清空。

## 上架前需要替换

- `Echoes/Domain/AppInfo.swift` 里的 `appStoreID`（当前是 `0000000000` 占位符）
- `Echoes/Domain/AppInfo.swift` 里的 `feedbackEmail`
- `Assets.xcassets/AppIcon.appiconset` 里的 App 图标（当前为空）

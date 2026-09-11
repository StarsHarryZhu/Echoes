# Echoes

拍下此刻的表情，按表情或按时间回看。

前置相机拍照 → 检测人脸 → 识别表情 → 归档。

底部是 tab 栏（三页：左「表情」、中空占位、右「时间」），**中间悬浮一颗圆形拍照键**，
压在 tab 栏正中。外观与重构前一致。

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
- `-uiCaptureOnce`：启动后自动走一次拍照流程。模拟器没有相机，
  这条参数正好用来验证「相机不可用 → 弹窗提示」这条错误路径

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

## 相机的行为

Echoes 需要**前置**相机，**没有兜底**：相机不可用时直接报错，由界面弹窗提示用户
（「Something went wrong / We couldn't find the front camera.」），
不会悄悄给一张替代图片。

判据是 `UIImagePickerController.isCameraDeviceAvailable(.front)`。
注意这两个 API 的答案**可以不一致** —— 实测 iOS 27 模拟器上：

| 环境 | `isSourceTypeAvailable(.camera)` | `isCameraDeviceAvailable(.front)` |
|---|---|---|
| 真机 | true | true |
| 模拟器 | **true** | **false** |

也就是说 camera 源报告可用，但并没有任何摄像头设备。所以不能拿 `.camera`
源可用当"有相机"用。

### 关于人脸照片夹具

`EchoesTests/Fixtures/` 里有几张人脸照片，用于验证「人脸检测 + CoreML 推理」
这条链路。它们**只在测试 bundle 里**，不在 app 包里 —— 测试资源不该随应用分发。
如果哪天想换掉，替换该目录下的 `sample1.jpg` 等文件即可。

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

# Flutter 调用本机 TTS（flutter_tts）

## 简介

本 Demo 与仓库里的 `android-kotlin-texttospeech-engine-demo` 做同一件事：**用系统安装的朗读引擎**朗读多行文本、可调语速。界面用 Flutter 绘制；真正发声的是插件在 **Android / iOS** 上调用的原生 `TextToSpeech`（Android）或系统语音 API（iOS），不是 Flutter 自己合成的假声音。

## 快速开始

### 环境要求

- 已安装 Flutter SDK（stable 3.x），命令行可运行 `flutter doctor`
- 真机或模拟器；Android 上需有可用的系统 TTS

### 运行

在本 README 所在目录（仓库根目录）执行：

```bash
flutter pub get
flutter run
```

指定 Android 设备时：

```bash
flutter run -d android
```

### 命令行只编译出 APK（安装包文件）

需要 `flutter doctor` 中 Android  toolchain 正常（已装 **Android SDK**，`ANDROID_HOME` 或 Android Studio 默认 SDK 路径可被找到，并已接受 license）。

**调试包**（体积大、含调试信息，签名 debug）：

```bash
cd /path/to/flutter-texttospeech-engine-demo
flutter build apk --debug
```

产物路径：

```text
build/app/outputs/flutter-apk/app-debug.apk
```

**发布包**（默认 release、已压缩，仍使用模板 debug 密钥；上架商店需自行配置正式签名）：

```bash
flutter build apk --release
```

产物路径：

```text
build/app/outputs/flutter-apk/app-release.apk
```

也可以打 **App Bundle**（上架 Google Play 用）：

```bash
flutter build appbundle --release
```

产物路径：

```text
build/app/outputs/bundle/release/app-release.aab
```

## 概念讲解

### 第一部分：为什么这还是「本机 TTS」

`flutter_tts` 通过 **Platform Channel** 调用各平台的原生实现。以 Android 为例，插件内部使用 `android.speech.tts.TextToSpeech`，与用户在使用 Legado 或纯 Kotlin Demo 时走的是同一类系统能力。Flutter 只负责按钮、输入框、滑块；**不替代**操作系统里的 TTS 引擎。

### 第二部分：分段排队（Android）

阅读软件里常见策略是：第一段 `QUEUE_FLUSH` 清空旧队列，后面每一段 `QUEUE_ADD` 排队。`flutter_tts` 暴露 `setQueueMode(0)` 与 `setQueueMode(1)`，与原生常量一致。本 Demo 在 **Android** 上按行分段后依次 `speak`。在 **iOS** 上没有同等队列模式，于是退化为 `awaitSpeakCompletion(true)` 后逐段 `speak`（效果仍是按顺序念完）。

### 第三部分：语速与 Legado 对齐

`flutter_tts` 的 Android 实现里，为了在多端统一参数，会把 Dart 传入的 `setSpeechRate` 值 **乘以 2** 再交给 `TextToSpeech.setSpeechRate`，并约定 Dart 侧 **0.5 对应原生 1.0（正常语速）**。Legado 使用 `(progress + 5) / 10` 作为原生语速（progress 为 0～45 的整数）。本 Demo 使用：

```dart
await _flutterTts.setSpeechRate((_rateProgress + 5) / 20.0);
```

这样插件乘 2 之后即为原生 `(progress + 5) / 10`，与 Kotlin Demo 一致。

勾选「跟随系统默认」时，对插件传入 **0.5**，对应原生 **1.0**，作为「不按滑块强行加速/降速」的基准；若设备在系统设置里还有其它 TTS 选项，以厂商实现为准。

## 完整示例

核心逻辑集中在 `lib/main.dart` 的 `_speak()` 与 `_applySpeechRate()`：先 `stop()`，再应用语速，再按平台选择 `setQueueMode` 或顺序 `speak`。

## 注意事项

- 首次使用某种语言时，系统可能提示下载语音包。
- **Web / Windows** 等平台的 `flutter_tts` 行为与手机不同；本 Demo 主要对照 **Android 本机 TTS**。
- 真机调试 TTS 比部分模拟器更可靠。

## 完整讲解（中文）

你可能担心：用 Flutter 做界面，声音是不是就变成「应用假装的」了？实际上不会。可以把它理解成：Flutter 是前台推销员，真正干活的还是手机操作系统里的朗读服务。`flutter_tts` 就像在推销员和操作系统之间打电话：你说「念这段字」，插件把话转到 Android 的 `TextToSpeech`，由用户已安装的引擎读出来。分段、排队、调速这些细节，和用 Kotlin 自己写几乎一样，只是换了一种语言和 UI 框架。唯一要小心的是**跨平台抽象**：插件为了同时照顾 iOS，语速参数在 Dart 里的刻度与「直接写 Android」略有换算关系，所以 README 里专门写了除以 20 再交给 `setSpeechRate`，这样乘 2 之后刚好等于 Legado 里那份公式。若你主要在 Android 上验证阅读类 App，用本 Demo 与 Kotlin Demo 对照即可快速确认行为是否一致。

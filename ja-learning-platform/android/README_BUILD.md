# Android 构建与运行

构建需要 JDK 21（例如 `JAVA_HOME=$(/usr/libexec/java_home -v 21)`），Node.js 22 或更新版本。先运行 `npm ci`。

## 两个环境

- `debug`：模拟器默认 `http://10.0.2.2:8080`，USB 真机默认 `http://localhost:8080`，使用本机 Vite 和代理到 `localhost:3000` 的后端。debug 包名带 `.debug`，可与 release 共存。
- `release`：默认 `https://japanese-learning-92jk.onrender.com`，页面和 `/api/v1` 同源，继续使用 HttpOnly Cookie。
- 地址由 Gradle buildTypes 决定，不依赖 `CAP_ENV` 或上次 cap sync。release 只允许 HTTPS，debug 才允许 HTTP。

```bash
# 先在 ja-learning-backend 中启动本地后端
npm run dev
# 然后在 ja-learning-platform 中启动 Vite（固定端口 8080）
npm run dev
# Debug 构建会自动为已连接、已授权的 USB 真机设置转发。
# 若构建后才连接手机，可手动执行；模拟器自动访问 10.0.2.2。
adb reverse tcp:8080 tcp:8080
# 另一个终端：准备资源、同步并打包
npm run build:android:dev
```

USB 转发无需修改 IP。通过 Wi-Fi 真机调试时，手机和电脑连接同一网络，构建时用 `./gradlew assembleDebug -PdevUrl=http://电脑局域网IP:8080`；模拟器地址可用 `-PemulatorUrl=http://10.0.2.2:8080` 覆盖。API 通过 Vite 转发，不需要手机直接访问后端端口。

## Release

在可信的本地环境设置 `ANDROID_KEYSTORE_FILE`（绝对路径）、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`，再运行 `npm run build:android:prod`。密钥和密码不写入仓库。自定义远程地址使用 `./gradlew assembleRelease -PreleaseUrl=https://你的域名`。

APK 在 `android/app/build/outputs/apk/`。Android Studio 也可直接选择 debug/release，Gradle 会准备完整内置语音资源。首次构建需要网络下载模型和 npm 依赖，后续复用本地资源。

## 页面更新与语音

release 是联网页面壳：每次启动加载 Render 页面，部署成功后重启应用即可获取新页面。后台接口更新直接生效。此方案不提供完整离线页面；原生代码、权限、语音引擎版本变化仍需升级 APK。

语音 Worker、JavaScript 引擎、ONNX Runtime/WASM、日语词典、模型、音色作为 `/native-tts-v1/` 打包在 APK。Android 只对当前应用同源的这个路径返回内置文件；缺失资源返回 404，不回退网络下载。网页端继续使用在线引擎。前端保留 v1 语音协议，避免 Render 部署破坏已安装 APK。

验收：真机/模拟器各启动 debug 并登录、调用接口；release 登录并确认同源 Cookie；首次合成后断网再合成一个未缓存的新词，确认无 CDN/HuggingFace 请求。仓库忽略模型、生成 assets、APK、数据库备份及签名文件。

## 系统栏安全区

`MainActivity` 在原生容器统一处理状态栏、系统导航栏、屏幕开孔及键盘的 Insets。WebView 放在安全区域内，已处理的 Insets 不再传给网页，避免 CSS 重复留白。此设置同时适用于 Debug 本地页面和 Release 远程页面；修改后必须重新打包安装 APK，仅部署网页不会更新原生窗口。`SafeAreaInstrumentedTest` 在解锁的设备上验证横竖屏 WebView 均未侵入系统栏区域。

## Kotlin 与语音回归

应用和设备测试源码位于 `app/src/main/kotlin/` 与 `app/src/androidTest/kotlin/`。项目使用 Kotlin 2.2.20、JDK 21；首次迁移后在 Android Studio 执行 Gradle Sync。

内置词典使用 `.tar.gz.bin` 保存，避免 AAPT 自动解压并重命名；WebView 仍通过原 `.tar.gz` URL 获取原始 gzip 字节。Open JTalk 在现有 TTS Worker 内执行，避免 WebView 无法拦截嵌套 Worker 资源请求。

设备回归类为 `com.jaleaning.app.BundledTtsInstrumentedTest`，验证打包后的 gzip 文件头和真实 WebView 语音合成。可在 Android Studio 运行该测试；生成测试 APK 后也可用 ADB instrumentation 执行。

三个服务地址统一放在 `android/gradle.properties` 的 `devUrl`、`emulatorUrl`、`releaseUrl` 中，并支持 `-P` 覆盖。Kotlin 不包含具体 URL。release 的全部地址字段都使用远程 HTTPS 地址。

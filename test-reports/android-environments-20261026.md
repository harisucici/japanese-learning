# Android 环境与内置语音验证（2026-10-26）

- 前端 Vitest：24/24 通过，包含初始化等待、最新请求优先、取消、失败重试。
- 后端回归：40/40 通过。使用工作目录中的本地数据库副本，补齐测试 schema；未操作远程库。练习/考试测试自行建立题目或试卷，避免依赖题库内容。
- 前端 Vite production 构建、Capacitor sync、后端 TypeScript 构建通过。
- JDK 21 下 debug/release APK 构建通过，release 签名验证通过。
- 两个 APK 均包含 19 个原生语音资源；模型 SHA256 与锁定清单一致，模型没有重复打入网页资源目录。
- 本地浏览器加载 APK 同一份 Worker/ONNX/WASM/词典资源，实际合成两个未缓存短句：80400、77400 个 24kHz PCM 采样，峰值非零。资源请求均在 `/native-tts-v1/` 路径。Worker 禁止外部模型请求，不回退 CDN。
- 生产页面首页已在浏览器实际打开。
- 用户模拟器报 localhost 连接拒绝时，已确认电脑 Vite 8080 和后端 3000 返回 HTTP 200，并为 emulator-5554 建立 8080 端口转发。代码已增加模拟器识别，默认使用 10.0.2.2；USB 真机使用 localhost 和 adb reverse。

仍需真机验收：Android WebView 内实际发音、远程 Render 部署后的页面更新和登录流程。浏览器合成验证不等同于这两项设备验收。既有 APK 需要先安装本次原生改动后的版本，此后仅网页/API 变化不需要重新安装。

## 设备复测与后续修正

- 修复 AAPT 把 `.tar.gz` 解压并改名为 `.tar` 导致词典 404：APK 内以 `.tar.gz.bin` 保存并检查字节与 npm 原始词典完全一致。
- 修复 Android WebView 嵌套 Worker 加载失败：Open JTalk 在已有语音 Worker 内执行，保持界面线程不阻塞。
- Kotlin 设备测试 `BundledTtsInstrumentedTest` 在 emulator-5554 通过：实际生成 41400 个采样，非零峰值 0.39404296875；不依赖网络模型。该测试补充了上文仅有的桌面浏览器合成验证。
- 应用源码与设备测试迁移为 Kotlin，移除旧 Java 和无效示例测试。
- 小说详情顶部改为独立的返回/栏目/字号工具栏，章节标题完整换行；移除移动端重复导航，字号面板可展开并限制 16–24px。

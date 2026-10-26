# Render 部署

此仓库的 `render.yaml` 将 Vue 页面和 Express API 部署为**一个 Web Service**。浏览器从同一域名调用 `/api/v1`，学习身份使用 `HttpOnly Cookie`。共享题库在内容 Turso 库；账号、学习会话、作答、成绩和复习记录在独立的用户 Turso 库，按 `userId` 隔离。

## 创建服务

1. 在 Render 中连接 GitHub 仓库 `harisucici/japanese-learning`，以 `feature/apk-version-updated` 分支创建 Blueprint，选择仓库根目录的 `render.yaml`。
2. Render 首次创建时填写两个未写入仓库的密钥：`TURSO_AUTH_TOKEN`（内容库）和 `USER_TURSO_AUTH_TOKEN`（独立用户库）。其他必需变量由 `render.yaml` 填入；`JWT_SECRET` 由 Render 生成。
3. 等待部署完成。一个 Web Service 同时提供 `/`、`/novel`、`/fun`、`/materials` 和 API；不要额外创建 Static Site。`PORT` 由 Render 提供，后端监听 `0.0.0.0`。

部署本次改动前，先备份两个 Turso 库，在可信环境中运行 `npm run db:init:users`，再运行 `npm run db:migrate:personal` 查看旧数据数量；确认后执行 `npm run db:migrate:personal -- --apply`。迁移脚本按 ID 跳过已复制行，不会删除内容库中的旧学习记录。核对各表数量后再切换应用版本。新环境还需完成内容库迁移。Render 免费 Web Service 不支持 pre-deploy command，所以这些数据库操作不放进 `render.yaml`。

注册默认开放，`ENABLE_USER_REGISTRATION=false` 可关闭。管理员账户需要在用户库中把指定 `User.role` 设为 `admin`，重新登录后可访问 `/admin`；普通用户不能访问管理 API。密码找回邮件需要同时配置 `RESEND_API_KEY`、`PASSWORD_RESET_FROM` 和 `PUBLIC_APP_URL`，缺少配置时接口会明确返回不可用，不会假装发送成功。

## 检查

已有的「仅后端」Web Service 不会自动应用仓库里的 `render.yaml`。若 Android Release 首页显示 `Not Found`、但 `/health` 正常，请在该服务的 Settings 中清空 Root Directory，将 Build Command 设为 `bash scripts/render-build.sh`，Start Command 设为 `node ja-learning-backend/dist/index.js`，并在 Environment 中设置 `SERVE_FRONTEND=true`。联合构建时 `VITE_API_BASE_URL` 和 `VITE_READING_API_BASE_URL` 均应为 `/api/v1`。重新部署后检查首页和资源地址，不能只检查 `/health`。

- `https://<服务域名>/health` 返回 `{ "status": "ok" }`。
- 直接打开 `https://<服务域名>/materials/material-101`，页面能加载文章和配套音频。
- 打开 `/fun` 可以看到题组并开始练习。创建匿名学习会话后，浏览器应收到 `HttpOnly` 的 `ja_session` Cookie；刷新后记录由服务端恢复。
- 若使用自定义域名，绑定到**同一个** Web Service。浏览器 API 基址是相对路径 `/api/v1`，不需要修改 Cookie 域名。

`DATABASE_URL=file:./dev.db` 仅供 Prisma 生成客户端时解析 SQLite 模式；运行时使用 `TURSO_URL`，不会创建或使用本地阅读数据库。`AUDIO_PUBLIC_BASE_URL` 是 Cloudinary 公开播放地址前缀，数据库只保存音频对象 ID。

Android release 加载此服务的页面，部署后重启应用即可更新网页。`/native-tts-v1/` 由 APK 拦截并提供内置语音资源，不上传 Render。Android 构建和调试步骤见 `ja-learning-platform/android/README_BUILD.md`。

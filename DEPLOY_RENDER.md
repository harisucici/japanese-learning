# Render 部署

此仓库的 `render.yaml` 将 Vue 页面和 Express API 部署为**一个 Web Service**。浏览器从同一域名调用 `/api/v1`，学习身份使用 `HttpOnly Cookie`，无需跨域设置。内容和学习记录仍在 Turso；Render 文件系统不保存文章、音频或用户数据。

## 创建服务

1. 在 Render 中连接 GitHub 仓库 `harisucici/japanese-learning`，以 `feature/add-music` 分支创建 Blueprint，选择仓库根目录的 `render.yaml`。
2. Render 首次创建时填写两个未写入仓库的密钥：`TURSO_AUTH_TOKEN`（内容库）和 `USER_TURSO_AUTH_TOKEN`（独立用户库）。其他必需变量由 `render.yaml` 填入；`JWT_SECRET` 由 Render 生成。
3. 等待部署完成。一个 Web Service 同时提供 `/`、`/novel`、`/fun`、`/materials` 和 API；不要额外创建 Static Site。`PORT` 由 Render 提供，后端监听 `0.0.0.0`。

现有两个 Turso 库已经完成初始化和内容迁移。若以后部署到全新的 Turso 库，需要先在可信环境中运行 `npm run db:init:users` 和 `npm run db:migrate:content`，再启动服务。Render 免费 Web Service 不支持 pre-deploy command，所以这些数据库操作不放进 `render.yaml`。

## 检查

- `https://<服务域名>/health` 返回 `{ "status": "ok" }`。
- 直接打开 `https://<服务域名>/materials/material-101`，页面能加载文章和配套音频。
- 打开 `/fun` 可以看到题组并开始练习。创建匿名学习会话后，浏览器应收到 `HttpOnly` 的 `ja_session` Cookie；刷新后记录由服务端恢复。
- 若使用自定义域名，绑定到**同一个** Web Service。浏览器 API 基址是相对路径 `/api/v1`，不需要修改 Cookie 域名。

`DATABASE_URL=file:./dev.db` 仅供 Prisma 生成客户端时解析 SQLite 模式；运行时使用 `TURSO_URL`，不会创建或使用本地阅读数据库。`AUDIO_PUBLIC_BASE_URL` 是 Cloudinary 公开播放地址前缀，数据库只保存音频对象 ID。

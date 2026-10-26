# 山間の書院 · Vue 前端

保留首页原有视觉设计，将原 Flutter 项目中四个学习入口的功能重建为 Vue 页面。Flutter 仅作为功能与接口参考；页面样式为独立设计。

## 技术栈

- Vue 3 + Vue Router：页面与动态路由
- Pinia：学习身份、答题会话与菜单状态
- Vite：开发与生产构建

## 接入的后端功能

- `/novel`：从 `/api/v1/learning/novel-lessons` 读取章节，支持搜索、分类、分章阅读、假名注释、词卡、原 PDF 与配套练习。
- `/fun`：从 `/api/v1/learning/fun-papers` 读取题组，按主题筛选，开始真实闯关会话。
- `/materials`：从 `/api/v1/learning/materials` 读取素材，支持搜索、分类、分页展示、详情、PDF、原文、译文与音视频。
- `/mock-exam`：从 `/api/v1/learning/exam-papers` 读取试卷和科目时长；只允许已完成校验的试卷开始考试。
- `/sessions/:id`：后端会话的答题、首次答案锁定、错题讲解、下一题、科目提交、计时和最终成绩；刷新后恢复进度。
- `/history`：读取真实学习记录、继续会话、登录已有账号。

没有生成模拟题或本地成绩。当前后端的全部整卷 `ready` 为 `false`，因此模拟考试入口正常展示试卷和规则，但开始按钮保持禁用，与 Flutter 数据流程一致。

## 本地运行

确认后端运行在 `http://localhost:3002`，然后在本目录执行：

```bash
npm install
npm run dev -- --port 4173
```

默认 API 地址为 `http://localhost:3002/api/v1`。如需更换地址，创建 `.env.local`：

```dotenv
VITE_API_BASE_URL=https://your-api.example.com/api/v1
```

`npm run build` 生成 `dist/`。远程部署时，浏览器必须能访问所配置的后端地址和素材文件；`localhost` 只适用于同一台电脑的本地运行。

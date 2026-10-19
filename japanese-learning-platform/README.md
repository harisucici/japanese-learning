# 日语 N5-N1 刷题与深度解析平台

商业级日语学习应用，支持 iOS、Android、Web 三端。

## 核心特性

- **多等级支持**: N5-N1 五个等级
- **深度解析**: 逐词拆解、句子结构、语法对比、引申练习
- **模拟考试**: 限时考试、分节计时、答题卡、自动交卷
- **智能复习**: 错题收录、间隔复习、薄弱点分析
- **多端同步**: 账号系统、云端存储、进度恢复
- **专业设计**: 遵循 design-taste-frontend 规范，商业级 UI

## 技术栈

- Flutter 3.16+
- Riverpod (状态管理)
- GoRouter (路由)
- Dio (网络)
- Hive (本地存储)
- AudioPlayers (音频播放)

## 开发阶段

### Phase 1: 核心学习流程 ✓ 进行中
- [x] 项目骨架与设计系统
- [ ] 账号系统与数据模型
- [ ] 题库浏览与筛选
- [ ] 答题流程与交互
- [ ] 题目深度解析
- [ ] 音频播放系统
- [ ] 错题本与收藏

### Phase 2: 考试与社交
- [ ] 模拟考试系统
- [ ] 成绩分析与统计
- [ ] 好友系统
- [ ] 共同挑战

### Phase 3: 内容扩展
- [ ] 题库管理后台
- [ ] 内容导入与审核
- [ ] AI 辅助生成
- [ ] 离线支持

## 运行项目

```bash
# 安装依赖
flutter pub get

# 运行代码生成
flutter pub run build_runner build

# 启动 Web
flutter run -d chrome

# 启动 iOS
flutter run -d ios

# 启动 Android
flutter run -d android
```

## 项目结构

```
lib/
├── main.dart                 # 入口
├── app.dart                  # App 配置与路由
├── core/                     # 核心模块
│   ├── theme/               # 设计系统
│   ├── router/              # 路由配置
│   ├── network/             # 网络层
│   ├── storage/             # 本地存储
│   └── utils/               # 工具类
├── features/                 # 功能模块
│   ├── auth/                # 账号系统
│   ├── home/                # 首页
│   ├── question_bank/       # 题库
│   ├── practice/            # 练习
│   ├── exam/                # 考试
│   ├── review/              # 复习
│   ├── analysis/            # 解析
│   └── profile/             # 个人中心
└── shared/                   # 共享组件与模型
    ├── models/              # 数据模型
    ├── widgets/             # 共享组件
    └── providers/           # 全局 Provider
```

## 设计规范

遵循 design-taste-frontend 技能规范：
- DESIGN_VARIANCE: 8 (非对称布局)
- MOTION_INTENSITY: 6 (流畅动效)
- VISUAL_DENSITY: 4 (清晰易读)

详细规范见 `docs/design-system.md`

## 团队

- Hermes: 编排与质量把控
- Turing 1-4: 并行开发
- Alan: 深度调研
- Mira: 文档与沟通

## License

Proprietary - All rights reserved

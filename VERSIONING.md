# 版本管理指南

本项目采用统一的版本号管理策略，确保前后端版本同步。

## 版本号规范

### 语义化版本 (Semantic Versioning)
格式: `MAJOR.MINOR.PATCH`

- **MAJOR (主版本号)**: 不兼容的 API 变更、重大功能重构
- **MINOR (次版本号)**: 向下兼容的功能新增
- **PATCH (修订号)**: 向下兼容的问题修正

### Flutter 构建号
前端使用 `version+build` 格式: `1.0.0+1`
- `version`: 语义化版本
- `build`: Flutter 构建号（递增整数）

## 当前版本

| 组件 | 版本 | 文件位置 |
|------|------|----------|
| 项目整体 | 1.1.0 | `CHANGELOG.md` |
| 后端 (Node.js) | 1.1.0 | `ja-learning-backend/package.json` |
| 前端 (Flutter) | 1.1.0+1 | `japanese-learning-platform/pubspec.yaml` |

## 版本同步流程

### 1. 更新版本号
当准备发布新版本时，同步更新以下文件:

```bash
# 后端版本
ja-learning-backend/package.json
  "version": "1.1.0"

# 前端版本
japanese-learning-platform/pubspec.yaml
  version: 1.1.0+2  # 构建号递增
```

### 2. 更新 CHANGELOG
在 `CHANGELOG.md` 中:
1. 将 `[Unreleased]` 下的内容移到新版本节点
2. 添加新版本号、发布日期
3. 分类整理变更（新增/修复/变更/移除/废弃）
4. 更新底部版本对比链接

### 3. Git 提交与标签
```bash
# 提交版本更新
git add CHANGELOG.md ja-learning-backend/package.json japanese-learning-platform/pubspec.yaml
git commit -m "chore: release v1.1.0"

# 创建标签
git tag -a v1.1.0 -m "Release v1.1.0: 前后端数据模型统一"

# 推送
git push origin main --tags
```

## 版本变更示例

### PATCH 版本 (1.1.0 → 1.1.1)
适用场景:
- Bug 修复
- 性能优化
- 文档更新
- 依赖升级（无 breaking changes）

### MINOR 版本 (1.1.0 → 1.2.0)
适用场景:
- 新增功能（向下兼容）
- 新增 API 端点
- 新增页面/组件
- 数据库新增字段（不删除/重命名）

### MAJOR 版本 (1.x.x → 2.0.0)
适用场景:
- 不兼容的 API 变更
- 数据库 schema 重构
- 删除功能/端点
- 重命名字段/接口
- 技术栈重大迁移

## 自动化版本管理（可选）

### 后端 (Node.js)
可使用 `npm version`:
```bash
cd ja-learning-backend
npm version patch  # 1.1.0 → 1.1.1
npm version minor  # 1.1.0 → 1.2.0
npm version major  # 1.1.0 → 2.0.0
```

### 前端 (Flutter)
手动更新 `pubspec.yaml`，或使用脚本:
```bash
cd japanese-learning-platform
# 更新版本号后
flutter pub get
flutter build web
```

## 标签命名规范

- 标准格式: `v1.2.3`
- 预发布: `v1.2.3-alpha.1`、`v1.2.3-beta.1`、`v1.2.3-rc.1`
- 后端专用: `backend-v1.2.3`（极少使用）
- 前端专用: `frontend-v1.2.3`（极少使用）

## 版本对比链接

CHANGELOG 底部应包含版本对比链接，方便查看 diff:

```markdown
[Unreleased]: https://github.com/harisucici/japanese-learning/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/harisucici/japanese-learning/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/harisucici/japanese-learning/releases/tag/v1.0.0
```

## 注意事项

1. **不要跳版本**: 按 1.0.0 → 1.0.1 → 1.1.0 → 2.0.0 顺序递增
2. **不要复用版本号**: 已发布的版本不可修改
3. **Breaking Changes 必须 MAJOR**: 即使只改一个字段也要升 MAJOR
4. **CHANGELOG 先行**: 先写 CHANGELOG，再改代码
5. **前后端同步**: 除非某端无变更，否则保持版本一致

## 当前版本历史

```
v1.1.0 (2026-10-19) - 前后端数据模型统一
  - Question/Grammar/OptionAnalysis 字段重构
  - JLPTLevel 枚举大小写统一
  - 修复重复数据 ID
  
v1.0.0 (2026-10-19) - 初始发布
  - 项目结构统一为 monorepo
  - 后端: Node.js + Express + Prisma
  - 前端: Flutter 3.27.4 Web
  - 50 道 N5 题目 + 完整解析系统
```

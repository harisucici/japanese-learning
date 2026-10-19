# 前后端数据模型统一 - P0 #1~#6 变更说明

## 修复概览

以**前端数据模型**（`lib/shared/models/*.dart`）为基准，修改后端 Prisma schema 和 Mock 数据，确保三端字段完全一致。

---

## P0 #1: Question 选项字段不匹配

**前端**: `QuestionOption { id, content, index, hint?, reading? }`  
**旧后端**: `{ id, text, isCorrect }`

**修复**:
- Mock 数据 `options[].text` → `options[].content`
- 添加 `index`（选项顺序）、`hint`、`reading` 字段
- 移除 `isCorrect`（正确性由 `answer` 字段通过 optionId 引用）

---

## P0 #2: Grammar 字段不匹配

**前端**: `GrammarPoint { name, connection, meaning, usage, exampleSentence?, exampleTranslation?, similarGrammars }`  
**旧后端**: `{ name, meaning, conjugation, examples[] }`

**修复**:
- Mock 数据 `grammar[].conjugation` → `grammar[].connection`
- Mock 数据 `grammar[].examples[0]` → `grammar[].exampleSentence`
- 添加 `usage`（使用场景）、`exampleTranslation`（例句翻译）、`similarGrammars`（相似语法对比）

---

## P0 #3: OptionAnalysis 字段不匹配

**前端**: `OptionAnalysis { optionId, isCorrect, reason, detail?, pitfall? }`  
**旧后端**: `{ optionId, analysis, isCorrect }`

**修复**:
- Mock 数据 `optionAnalysis[].analysis` → `optionAnalysis[].reason`
- 添加 `detail`（详细解析）、`pitfall`（易错点）

---

## P0 #4: Extensions 字段不匹配

**前端**: `ExtensionExercise { id, type, content, options[], answer, explanation?, relatedTags[] }`  
**旧后端**: `{ title, content }`

**修复**:
- 完全重构 extensions 结构
- 添加 `id`（练习 ID）、`type`（练习类型）、`options[]`（选择题选项）、`answer`、`explanation`、`relatedTags[]`
- 旧 `title` 迁移到 `relatedTags[]`

---

## P0 #5: Prisma schema 缺少 explanationId 字段

**前端**: `Question.explanationId`（必填 String）

**修复**:
- Prisma Question 模型添加 `explanationId String` 字段
- 移除 Explanation 和 Question 之间的 Prisma 外键关联（保持 ID 引用灵活，与前端一致）

---

## P0 #6: JLPTLevel 枚举大小写不一致

**前端**: `n5, n4, n3, n2, n1`（小写）  
**旧后端**: `N5, N4, N3, N2, N1`（大写）

**修复**:
- Prisma 枚举改为 `n5, n4, n3, n2, n1`
- User 模型默认值改为 `n5`
- ReviewStatus 的 `new` 改为 `new_`（避免 SQL 关键字冲突，与前端一致）

---

## 额外修复: Question 模型补全

- 添加 `contentReading`（题干读音）、`contentImageUrl`（题干图片）、`audioUrl`（音频 URL）
- 添加 `order`（题目顺序）

---

## 额外修复: Explanation 模型补全

- 添加 `note`（学习重点 / 备注）

---

## 修复重复数据

- 原有 50 条问题，2 个重复 ID（q-n5-023、q-n5-024 各出现 2 次）
- 修复后 50 条唯一 ID（重复项追加 `-dup` 后缀）

---

## 验证结果

- ✅ `prisma validate` 通过
- ✅ JSON 可解析
- ✅ 50 条问题，50 条解析，全部唯一 ID
- ✅ 所有 `question.explanationId` 引用有效
- ✅ 所有 `explanation.questionId` 引用有效
- ✅ 字段名称前后端完全一致

# 数据库学习流程

前端实际入口为 `lib/main.dart` → `database_learning/database_app.dart`。
运行时不读取 assets/data 题库，不使用原静态练习列表、假题数或假完成状态。

## 启动

后端目录：

```sh
npm run build
npm run start
```

`.env` 默认端口为 3002；API 根路径为 `/api/v1/learning`。
首次在新数据库启动前执行 `npx prisma migrate deploy`。

前端目录：

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8081
```

或者构建后通过静态服务提供页面：

```sh
flutter build web --release --pwa-strategy=none
python3 -m http.server 8081 --bind 127.0.0.1 --directory build/web
```

可通过 `--dart-define=API_BASE_URL=http://localhost:3002/api/v1` 配置后端。

## 数据与答题规则

- PostgreSQL `Question` / `Explanation` 是题目与讲解的唯一来源。
- 仅显示具有官方来源信息且 source 为 official/pastExam 的题目。
- `LearningSession` 保存题目顺序、进度和完成时间；`LearningAnswer` 保存不可覆盖的首次答案。
- 每题选择即提交，由后端核对正确选项。答对前进；答错停留、返回标准答案与项目编写的讲解，手动继续。
- 同一次练习中，重复提交任何已答题均返回 409；数据库唯一键防止重复计分。
- 全部作答后按 `round(答对题数 / 总题数 * 100)` 计算练习总分，写入 `ExamRecord`。
- 不把本练习分数称为 JLPT 官方换算分数，也不把 2018 出版年份当成考试年份。
- 刷新 `/sessions/:id` 可从数据库恢复同一次练习。错误答案仍锁定。
- 服务不可用时显示错误与重试入口，不提供本地题库兜底。
- 本机学习者是真实数据库账号，浏览器仅保存令牌。也可登录已有账号。

## 核验

后端 `node scripts/check-learning-flow.js` 针对实际数据库检查重复提交、并发提交、顺序、错题锁定、持久化、隔离及 67/0/100 分结果；会删除其创建的验收账号与记录。
前端 `flutter test` 包含真实接口响应回放的布局、交互及成绩页回归测试。回放文件仅用于测试，不打入应用包。

中文学习讲解为项目编写，标准答案取自官方正答表，二者明确区分。未导入的题型显示零题。

## 完整试卷模拟考试

- `/exams` 页面从数据库列出试卷及完整性状态，可勾选即时错题讲解，默认关闭。
- `LearningSession.examConfig` 保存试卷、科目、服务器截止时间和讲解设置。到时关闭本科目，未作答计零分；下科单独开始，不继承上科剩余时间。
- 开启讲解也不暂停考试计时；关闭时考试中不返回正确选项、正确性或讲解。成绩不是 JLPT 官方量尺分。
- N1 当前 110/55 分钟；N2 105/50；N3 30/70/40；N4 25/55/35；N5 20/40/30。N1 在 2022 年 12 月前听力为 60 分钟，N4/N5 在 2020 年 12 月前分别为 30/60/35、25/50/30。
- 官方规则来源：https://www.jlpt.jp/e/guideline/testsections.html
- 官方不发布每场完整原卷的说明：https://www.jlpt.jp/e/faq/
- 目前登记的 10 组官方问题集材料是出版于 2012、2018 年的历次真题选编，均尚未完整录题，不冒充某年完整真题，不允许启动整卷考试。

### 导入完整试卷

后端执行 `node scripts/import-full-paper.js /绝对路径/manifest.json`。
导入前题目、标准答案必须已在 Question 中逐题核验，provenance 记录原卷文件 SHA256；有考试年月的卷子还需记录 examYear/examMonth。
Manifest 必须包含 id（小写字母、数字和连字符）、title、level、kind（dated_exam/official_workbook）、examYear/examMonth（有确切年月时）、reviewedBy、reviewedAt、sections、materials。
每个 section 必须包含 id、minutes、expectedCount、questionIds；听力另有 audioFiles（一个完整科目的原始音频文件）。
每个 material 包含 file（相对于 manifest 的路径）、sha256、role（question_paper/answer_key/listening_audio）。
导入器检查所有科目、题量、题型、标准答案、来源年月、原始文件校验值、听力音频和对应时期时长；不补造任何缺失材料。文件复制到 data/exam-assets 后由后端提供。
开启即时讲解还要求该卷所有题目都有讲解，缺讲解时拒绝开启而不是编造。

后端 `node scripts/check-exam-flow.js` 验证历史时间规则、拒绝不完整试卷、禁止计时重置、开关隐私、到时锁科、手动开下一科及未答题计分。验收数据与账号会清理。

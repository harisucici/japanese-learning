# 山間の書院：Turso 迁移包

这是一个完整的本地数据库快照。`learning.sqlite` 同时包含业务数据和原始资料文件，不依赖原电脑的绝对路径。`learning.sql` 是同一快照的可重建 SQL 备份。数据库尚未上传到 Turso；当前网站仍使用 PostgreSQL。

## 数据范围

- 所有现有题目、答案、讲解、来源、官方试卷元数据、趣味试卷、资料正文和中文译文。
- 所有现有账户（含密码哈希）、练习会话、首次作答、成绩和复习记录；各表实际数量见 `manifest.json`。没有记录的表保持为空。
- 本地已有的 PDF、音频和视频全部内嵌：`Asset` 是文件元数据，`AssetChunk` 按 64 KiB 保存二进制，`AssetPath` 保存相对文件路径，`AssetReference` 把业务对象关联到文件。
- 外部官方链接保留；尚未下载的资料只有来源链接，没有伪造文件或增加“已入库”状态。选编题仍标记为选编，未补齐的完整试卷仍不可用。

## 检查与导入

先在此目录运行（Python 3 标准库，无需额外安装包）：

```sh
python3 verify.py learning.sqlite manifest.json
```

登录 Turso CLI 后，创建一个**新数据库**并导入：

```sh
bash import-turso.sh japanese-learning
```

也可直接运行官方 CLI 命令：

```sh
turso db create japanese-learning --from-file ./learning.sqlite
```

脚本会将本包的完整数据上传到你的 Turso 账户；包括现有账户及个人学习记录。它不删除或覆盖已有远程数据库。不在前端保存数据库 token。

命令依据：[Turso db create 官方文档](https://docs.turso.tech/cli/db/create)。迁移文件使用 WAL 模式，已完成 checkpoint，提交数据都在主文件中，无需依赖 `-wal` 文件。

导入后检查：

```sql
SELECT source, level, count(*) FROM Question GROUP BY source, level;
SELECT count(*) FROM StudyMaterial;
SELECT count(*), sum(byteLength) FROM Asset;
PRAGMA foreign_key_check;
```

`foreign_key_check` 应无结果。数量应与 `manifest.json` 一致。

## 数据约定

保留原模型名称和字段名，便于逐字段迁移。PostgreSQL 枚举转换为带 CHECK 约束的 TEXT；数组和 JSON 转为有效的 JSON TEXT；布尔值为 INTEGER 0/1；时间为 ISO-8601 UTC 字符串。保留 ID、题目顺序、首次作答和来源校验值。`source-models.json` 是字段类型映射。

已有外键与唯一约束转入 SQLite；另有目录、记录和文件引用索引。`QuestionOption`、`QuestionTag`、`FunPaperQuestion`、`FunPaperMaterial`、`SessionQuestion`、`RecordQuestion`、`ExamSection`、`ExamSectionQuestion` 是基于 JSON 的只读关系视图，可直接 JOIN 查询，避免重复存储和更新不一致。修改时写入对应主表 JSON 字段。

例如按题组顺序读取题目：

```sql
SELECT q.* FROM FunPaperQuestion p
JOIN Question q ON q.id=p.questionId
WHERE p.paperId='material-adventure-01' ORDER BY p.position;
```

文件按 SHA256 去重。读取时按 `AssetChunk.ordinal` 排序拼接；`Asset.mimeType` 是响应类型，`byteLength` 是总大小。文件关联见 `AssetReference(ownerTable,ownerId,jsonPointer)`。已下载的官方 PDF 同时有官方来源 URL 和内嵌文件关联。

恢复为普通文件（输出目录必须不存在）：

```sh
python3 restore-assets.py learning.sqlite ./restored-media
```

## 网站连接切换的边界

此包已完成**数据整理和迁移准备**。现有后端使用 Prisma 5 + PostgreSQL；不能只替换 DATABASE_URL 就连接本包或 Turso。正式切换时须使用 SQLite/libSQL 数据访问层，处理 JSON 解码、布尔值、事务、ID 与时间默认值、文件块流式读取，并回归答题锁定与计分接口。导出表刻意不加数据库专用 UUID/时间默认函数，写入层需要提供这些值。

包内没有 Turso token、原 `.env`、JWT 密钥或原电脑绝对文件路径。当前网站不受导出影响。新增数据后可重新导出新的快照，而不是反复导入旧包。

后端项目已提供：

```sh
npm run db:export:turso -- --out /path/to/new-export-directory
```

默认从同一 PostgreSQL Repeatable Read 事务读取全部业务表；禁止覆盖已存在的输出目录。`manifest.json` 最后写入，只有它存在才表示导出结束。

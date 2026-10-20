/**
 * 知识条目（词汇/语法）输入校验
 * 使用 zod 做应用层校验，与 learning.validators.ts 风格保持一致
 */
import { z } from 'zod';

// JLPT 等级枚举（与 Question.level 一致）
export const jlptLevelEnum = z.enum(['n5', 'n4', 'n3', 'n2', 'n1', 'ungraded']);

// 例句 schema：[{ jp, zh, reading? }]
export const exampleSentenceSchema = z
  .array(
    z.object({
      jp: z.string().min(1),
      zh: z.string().optional(),
      reading: z.string().optional(),
    }),
  )
  .default([]);

// 词汇创建
export const createVocabularySchema = z.object({
  word: z.string().min(1, '词汇不能为空'),
  reading: z.string().min(1, '读音不能为空'),
  meaning: z.string().min(1, '含义不能为空'),
  level: jlptLevelEnum,
  exampleSentences: exampleSentenceSchema,
  note: z.string().optional(),
  // 关联词 [{ toVocabularyId, type }]
  relations: z
    .array(
      z.object({
        toVocabularyId: z.string().uuid(),
        // synonym | antonym | related
        type: z.enum(['synonym', 'antonym', 'related']),
      }),
    )
    .optional()
    .default([]),
});

// 词汇更新（所有字段可选）
export const updateVocabularySchema = createVocabularySchema.partial();

// 语法创建
export const createGrammarSchema = z.object({
  name: z.string().min(1, '语法名称不能为空'),
  structure: z.string().min(1, '结构不能为空'),
  meaning: z.string().min(1, '含义不能为空'),
  level: jlptLevelEnum,
  usage: z.record(z.any()).default({}),
  exampleSentences: exampleSentenceSchema,
  note: z.string().optional(),
  // 关联语法 [{ toGrammarId, type }]
  relations: z
    .array(
      z.object({
        toGrammarId: z.string().uuid(),
        // similar | confusable
        type: z.enum(['similar', 'confusable']),
      }),
    )
    .optional()
    .default([]),
});

// 语法更新
export const updateGrammarSchema = createGrammarSchema.partial();

// 通用查询 query
export const listQuerySchema = z.object({
  level: z.string().transform(v => v.toLowerCase()).pipe(jlptLevelEnum).optional(),
  limit: z.coerce.number().int().min(1).max(200).optional(),
  offset: z.coerce.number().int().min(0).optional(),
});

/**
 * 词汇服务
 * 处理词汇 CRUD、关联词查询、反向索引（关联题目）
 */
import prisma from '../config/database';

type ListParams = {
  level?: string;
  limit?: number;
  offset?: number;
};

type CreateInput = {
  word: string;
  reading: string;
  meaning: string;
  level: string;
  exampleSentences?: any;
  note?: string;
  relations?: Array<{ toVocabularyId: string; type: string }>;
};

type UpdateInput = Partial<CreateInput>;

export class VocabularyService {
  /** 按条件分页列出词汇（含关联数量统计） */
  async list(params: ListParams) {
    const where: any = {};
    if (params.level) where.level = params.level.toLowerCase();

    const [items, total] = await Promise.all([
      prisma.vocabulary.findMany({
        where,
        take: params.limit ?? 20,
        skip: params.offset ?? 0,
        orderBy: { createdAt: 'desc' },
        include: {
          synonymsFrom: {
            select: { type: true, toVocabularyId: true },
          },
        },
      }),
      prisma.vocabulary.count({ where }),
    ]);

    return { items, total };
  }

  /** 按 ID 查询词汇详情，含关联词（双向）和关联题目数 */
  async getById(id: string) {
    const item = await prisma.vocabulary.findUnique({
      where: { id },
      include: {
        synonymsFrom: {
          include: { toVocabulary: { select: { id: true, word: true, reading: true, level: true } } },
        },
        synonymsTo: {
          include: { fromVocabulary: { select: { id: true, word: true, reading: true, level: true } } },
        },
        _count: { select: { questions: true } },
      },
    });
    if (!item) return null;

    // 合并双向关联，去重
    const related = new Map<string, any>();
    for (const r of item.synonymsFrom) {
      related.set(r.toVocabularyId, { ...r.toVocabulary, relationType: r.type });
    }
    for (const r of item.synonymsTo) {
      if (!related.has(r.fromVocabularyId)) {
        related.set(r.fromVocabularyId, { ...r.fromVocabulary, relationType: r.type });
      }
    }

    const { synonymsFrom, synonymsTo, _count, ...rest } = item;
    return { ...rest, related: Array.from(related.values()), questionCount: _count.questions };
  }

  /** 创建词汇及关联词（事务） */
  async create(input: CreateInput) {
    return prisma.$transaction(async (tx) => {
      const vocab = await tx.vocabulary.create({
        data: {
          word: input.word,
          reading: input.reading,
          meaning: input.meaning,
          level: input.level.toLowerCase(),
          exampleSentences: input.exampleSentences ?? [],
          note: input.note,
        },
      });

      if (input.relations && input.relations.length > 0) {
        await tx.vocabularyRelation.createMany({
          data: input.relations.map((r) => ({
            fromVocabularyId: vocab.id,
            toVocabularyId: r.toVocabularyId,
            type: r.type,
          })),
        });
      }

      return this.getById(vocab.id);
    });
  }

  /** 更新词汇：字段级更新；若传入 relations 则整体替换关联 */
  async update(id: string, input: UpdateInput) {
    const existing = await prisma.vocabulary.findUnique({ where: { id } });
    if (!existing) return null;

    return prisma.$transaction(async (tx) => {
      await tx.vocabulary.update({
        where: { id },
        data: {
          ...(input.word !== undefined && { word: input.word }),
          ...(input.reading !== undefined && { reading: input.reading }),
          ...(input.meaning !== undefined && { meaning: input.meaning }),
          ...(input.level !== undefined && { level: input.level.toLowerCase() }),
          ...(input.exampleSentences !== undefined && { exampleSentences: input.exampleSentences }),
          ...(input.note !== undefined && { note: input.note }),
        },
      });

      if (input.relations !== undefined) {
        // 替换：先删后建
        await tx.vocabularyRelation.deleteMany({ where: { fromVocabularyId: id } });
        if (input.relations.length > 0) {
          await tx.vocabularyRelation.createMany({
            data: input.relations.map((r) => ({
              fromVocabularyId: id,
              toVocabularyId: r.toVocabularyId,
              type: r.type,
            })),
          });
        }
      }

      return this.getById(id);
    });
  }

  /** 反向索引：获取所有关联该词汇的题目（分页） */
  async getQuestions(id: string, limit = 20, offset = 0) {
    const existing = await prisma.vocabulary.findUnique({ where: { id }, select: { id: true } });
    if (!existing) return null;

    const where = { vocabularyId: id };
    const [items, total] = await Promise.all([
      prisma.question.findMany({
        where,
        take: limit,
        skip: offset,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          level: true,
          type: true,
          content: true,
          options: true,
          answer: true,
          difficulty: true,
          tags: true,
          createdAt: true,
        },
      }),
      prisma.question.count({ where }),
    ]);
    return { items, total };
  }
}

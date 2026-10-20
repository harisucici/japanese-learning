/**
 * 语法服务
 * 处理语法 CRUD、关联语法查询、反向索引（关联题目）
 */
import prisma from '../config/database';

type ListParams = {
  level?: string;
  limit?: number;
  offset?: number;
};

type CreateInput = {
  name: string;
  structure: string;
  meaning: string;
  level: string;
  usage?: any;
  exampleSentences?: any;
  note?: string;
  relations?: Array<{ toGrammarId: string; type: string }>;
};

type UpdateInput = Partial<CreateInput>;

export class GrammarService {
  /** 按条件分页列出语法 */
  async list(params: ListParams) {
    const where: any = {};
    if (params.level) where.level = params.level.toLowerCase();

    const [items, total] = await Promise.all([
      prisma.grammar.findMany({
        where,
        take: params.limit ?? 20,
        skip: params.offset ?? 0,
        orderBy: { createdAt: 'desc' },
        include: {
          relationsFrom: {
            select: { type: true, toGrammarId: true },
          },
        },
      }),
      prisma.grammar.count({ where }),
    ]);

    return { items, total };
  }

  /** 按 ID 查询语法详情，含关联语法（双向）和关联题目数 */
  async getById(id: string) {
    const item = await prisma.grammar.findUnique({
      where: { id },
      include: {
        relationsFrom: {
          include: { toGrammar: { select: { id: true, name: true, structure: true, level: true } } },
        },
        relationsTo: {
          include: { fromGrammar: { select: { id: true, name: true, structure: true, level: true } } },
        },
        _count: { select: { questions: true } },
      },
    });
    if (!item) return null;

    // 合并双向关联，去重
    const related = new Map<string, any>();
    for (const r of item.relationsFrom) {
      related.set(r.toGrammarId, { ...r.toGrammar, relationType: r.type });
    }
    for (const r of item.relationsTo) {
      if (!related.has(r.fromGrammarId)) {
        related.set(r.fromGrammarId, { ...r.fromGrammar, relationType: r.type });
      }
    }

    const { relationsFrom, relationsTo, _count, ...rest } = item;
    return { ...rest, related: Array.from(related.values()), questionCount: _count.questions };
  }

  /** 创建语法及关联（事务） */
  async create(input: CreateInput) {
    return prisma.$transaction(async (tx) => {
      const g = await tx.grammar.create({
        data: {
          name: input.name,
          structure: input.structure,
          meaning: input.meaning,
          level: input.level.toLowerCase(),
          usage: input.usage ?? {},
          exampleSentences: input.exampleSentences ?? [],
          note: input.note,
        },
      });

      if (input.relations && input.relations.length > 0) {
        await tx.grammarRelation.createMany({
          data: input.relations.map((r) => ({
            fromGrammarId: g.id,
            toGrammarId: r.toGrammarId,
            type: r.type,
          })),
        });
      }

      return this.getById(g.id);
    });
  }

  /** 更新语法：字段级更新；若传入 relations 则整体替换关联 */
  async update(id: string, input: UpdateInput) {
    const existing = await prisma.grammar.findUnique({ where: { id } });
    if (!existing) return null;

    return prisma.$transaction(async (tx) => {
      await tx.grammar.update({
        where: { id },
        data: {
          ...(input.name !== undefined && { name: input.name }),
          ...(input.structure !== undefined && { structure: input.structure }),
          ...(input.meaning !== undefined && { meaning: input.meaning }),
          ...(input.level !== undefined && { level: input.level.toLowerCase() }),
          ...(input.usage !== undefined && { usage: input.usage }),
          ...(input.exampleSentences !== undefined && { exampleSentences: input.exampleSentences }),
          ...(input.note !== undefined && { note: input.note }),
        },
      });

      if (input.relations !== undefined) {
        await tx.grammarRelation.deleteMany({ where: { fromGrammarId: id } });
        if (input.relations.length > 0) {
          await tx.grammarRelation.createMany({
            data: input.relations.map((r) => ({
              fromGrammarId: id,
              toGrammarId: r.toGrammarId,
              type: r.type,
            })),
          });
        }
      }

      return this.getById(id);
    });
  }

  /** 反向索引：获取所有关联该语法的题目 */
  async getQuestions(id: string, limit = 20, offset = 0) {
    const existing = await prisma.grammar.findUnique({ where: { id }, select: { id: true } });
    if (!existing) return null;

    const where = { grammarId: id };
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

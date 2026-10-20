/**
 * 内容管理服务
 * 处理题目的 CRUD、发布、撤回等操作
 */
import prisma from '../config/database';

type QuestionListParams = {
  level?: string;
  type?: string;
  status?: string;
  source?: string;
  limit?: number;
  offset?: number;
};

type QuestionUpdateInput = {
  level?: string;
  type?: string;
  content?: string;
  contentReading?: string | null;
  options?: any;
  answer?: string;
  source?: string;
  provenance?: any;
  tags?: string[];
  difficulty?: number;
  order?: number;
  vocabularyId?: string | null;
  grammarId?: string | null;
};

export class ContentService {
  /**
   * 查询所有题目（支持分页和过滤）
   * 默认过滤掉软删除的题目
   */
  async list(params: QuestionListParams) {
    const where: any = { deletedAt: null };
    if (params.level) where.level = params.level.toLowerCase();
    if (params.type) where.type = params.type;
    if (params.status) where.status = params.status;
    if (params.source) where.source = params.source;

    const [items, total] = await Promise.all([
      prisma.question.findMany({
        where,
        take: params.limit ?? 20,
        skip: params.offset ?? 0,
        orderBy: { createdAt: 'desc' },
        include: {
          vocabulary: { select: { id: true, word: true, reading: true } },
          grammar: { select: { id: true, name: true, structure: true } },
        },
      }),
      prisma.question.count({ where }),
    ]);

    return { items, total };
  }

  /**
   * 查询题目详情（含解析）
   */
  async getById(id: string) {
    const question = await prisma.question.findFirst({
      where: { id, deletedAt: null },
      include: {
        vocabulary: { select: { id: true, word: true, reading: true } },
        grammar: { select: { id: true, name: true, structure: true } },
      },
    });
    if (!question) return null;

    const explanation = await prisma.explanation.findUnique({
      where: { questionId: id },
    });

    return { ...question, explanation };
  }

  /**
   * 更新题目
   */
  async update(id: string, data: QuestionUpdateInput) {
    const existing = await prisma.question.findFirst({
      where: { id, deletedAt: null },
    });
    if (!existing) return null;

    return prisma.question.update({
      where: { id },
      data: {
        ...(data.level !== undefined && { level: data.level.toLowerCase() }),
        ...(data.type !== undefined && { type: data.type }),
        ...(data.content !== undefined && { content: data.content }),
        ...(data.contentReading !== undefined && { contentReading: data.contentReading }),
        ...(data.options !== undefined && { options: data.options }),
        ...(data.answer !== undefined && { answer: data.answer }),
        ...(data.source !== undefined && { source: data.source }),
        ...(data.provenance !== undefined && { provenance: data.provenance }),
        ...(data.tags !== undefined && { tags: data.tags }),
        ...(data.difficulty !== undefined && { difficulty: data.difficulty }),
        ...(data.order !== undefined && { order: data.order }),
        ...(data.vocabularyId !== undefined && { vocabularyId: data.vocabularyId }),
        ...(data.grammarId !== undefined && { grammarId: data.grammarId }),
      },
    });
  }

  /**
   * 软删除题目
   */
  async delete(id: string) {
    const existing = await prisma.question.findFirst({
      where: { id, deletedAt: null },
    });
    if (!existing) return null;

    return prisma.question.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  /**
   * 发布题目
   */
  async publish(id: string) {
    const existing = await prisma.question.findFirst({
      where: { id, deletedAt: null },
    });
    if (!existing) return null;

    const options = Array.isArray(existing.options) ? existing.options as any[] : [];
    const explanation = await prisma.explanation.findUnique({ where: { questionId: id } });
    const analyses = Array.isArray(explanation?.optionAnalysis) ? explanation.optionAnalysis as any[] : [];
    if (!options.length || !options.some(option => option.id === existing.answer)) {
      throw Object.assign(new Error('选项或标准答案不完整，无法发布'), { status: 400 });
    }
    if (!explanation?.translation || !explanation.sentenceStructure || options.some(option => !analyses.some(analysis => analysis.optionId === option.id && analysis.reason))) {
      throw Object.assign(new Error('逐句解析或逐项说明不完整，无法发布'), { status: 400 });
    }
    if (['official', 'pastExam'].includes(existing.source) && !existing.provenance) {
      throw Object.assign(new Error('官方来源缺少核实信息，无法发布'), { status: 400 });
    }

    return prisma.question.update({
      where: { id },
      data: {
        status: 'published',
        publishedAt: new Date(),
      },
    });
  }

  /**
   * 撤回题目（从发布改为草稿）
   */
  async unpublish(id: string) {
    const existing = await prisma.question.findFirst({
      where: { id, deletedAt: null },
    });
    if (!existing) return null;

    return prisma.question.update({
      where: { id },
      data: {
        status: 'draft',
      },
    });
  }
}

import prisma from '../config/database';

export class QuestionService {
  async list(params: { level?: string; type?: string; limit?: number; offset?: number }) {
    const where: any = { status: 'published', deletedAt: null };
    if (params.level) where.level = params.level.toLowerCase();
    if (params.type) where.type = params.type;
    const [items, total] = await Promise.all([
      prisma.question.findMany({
        where,
        take: params.limit ?? 20,
        skip: params.offset ?? 0,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.question.count({ where }),
    ]);
    return { items: items.map(publicQuestion), total };
  }

  async getById(id: string) {
    const question = await prisma.question.findFirst({ where: { id, status: 'published', deletedAt: null } });
    return question ? publicQuestion(question) : null;
  }

  async getByLevel(level: string) {
    const questions = await prisma.question.findMany({
      where: { level: level.toLowerCase() as any, status: 'published', deletedAt: null },
      orderBy: { createdAt: 'desc' },
    });
    return questions.map(publicQuestion);
  }
}

function publicQuestion(question: any) {
  const { answer, explanationId, difficulty, ...visible } = question;
  if (visible.provenance) {
    const { correctOption, answer: sourceAnswer, ...source } = visible.provenance;
    visible.provenance = source;
  }
  return visible;
}

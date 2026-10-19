import prisma from '../config/database';

export class QuestionService {
  async list(params: { level?: string; type?: string; limit?: number; offset?: number }) {
    const where: any = {};
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
    return { items, total };
  }

  async getById(id: string) {
    return prisma.question.findUnique({ where: { id } });
  }

  async getByLevel(level: string) {
    return prisma.question.findMany({
      where: { level: level.toLowerCase() as any },
      orderBy: { createdAt: 'desc' },
    });
  }
}

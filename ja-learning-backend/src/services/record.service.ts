import prisma from '../config/database';

export class RecordService {
  async create(userId: string, data: {
    level: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
    recordType: 'practice' | 'exam' | 'review';
    questionIds: string[];
    answers: { questionId: string; selectedOptionId?: string; userAnswer?: string; isCorrect: boolean; timeSpent?: number }[];
    durationMs: number;
  }) {
    const correctCount = data.answers.filter(a => a.isCorrect).length;
    const score = data.questionIds.length > 0
      ? Math.round((correctCount / data.questionIds.length) * 100)
      : 0;
    return prisma.examRecord.create({
      data: {
        userId,
        level: data.level,
        recordType: data.recordType,
        questionIds: data.questionIds,
        answers: data.answers.map(a => ({
          questionId: a.questionId,
          selectedOptionId: a.selectedOptionId || a.userAnswer,
          isCorrect: a.isCorrect ?? false,
          timeSpent: a.timeSpent ?? 0,
        })) as any,
        totalQuestions: data.questionIds.length,
        correctCount,
        score,
        durationMs: data.durationMs,
      },
    });
  }

  async listByUser(userId: string) {
    return prisma.examRecord.findMany({
      where: { userId },
      orderBy: { completedAt: 'desc' },
    });
  }

  async getById(id: string) {
    return prisma.examRecord.findUnique({
      where: { id },
    });
  }
}

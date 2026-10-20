import prisma from '../config/database';
import userPrisma from '../config/user-database';

export class RecordService {
  async create(userId: string, data: {
    level: 'n5' | 'n4' | 'n3' | 'n2' | 'n1';
    recordType: 'practice' | 'exam' | 'review';
    questionIds: string[];
    answers: { questionId: string; selectedOptionId?: string; userAnswer?: string; isCorrect: boolean; timeSpent?: number }[];
    durationMs: number;
  }) {
    const questions = await prisma.question.findMany({ where: { id: { in: data.questionIds } } });
    if (questions.length !== data.questionIds.length || data.answers.length !== data.questionIds.length || new Set(data.questionIds).size !== data.questionIds.length) {
      throw Object.assign(new Error('题目或作答数量不匹配'), { status: 400 });
    }
    const answerById = new Map(data.answers.map(a => [a.questionId, a]));
    const checked = questions.map(q => {
      const answer = answerById.get(q.id);
      if (!answer) throw Object.assign(new Error('作答缺少题目'), { status: 400 });
      const selected = answer.selectedOptionId || answer.userAnswer || '';
      return { questionId: q.id, selectedOptionId: selected, isCorrect: q.answer === selected, timeSpent: answer.timeSpent ?? 0 };
    });
    const correctCount = checked.filter(a => a.isCorrect).length;
    const score = data.questionIds.length > 0
      ? Math.round((correctCount / data.questionIds.length) * 100)
      : 0;
    return userPrisma.examRecord.create({
      data: {
        userId,
        level: data.level,
        recordType: data.recordType,
        questionIds: data.questionIds,
        answers: checked as any,
        totalQuestions: data.questionIds.length,
        correctCount,
        score,
        durationMs: data.durationMs,
      },
    });
  }

  async listByUser(userId: string) {
    return userPrisma.examRecord.findMany({
      where: { userId },
      orderBy: { completedAt: 'desc' },
    });
  }

  async getById(id: string) {
    return userPrisma.examRecord.findUnique({
      where: { id },
    });
  }
}

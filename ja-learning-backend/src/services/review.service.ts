import prisma from '../config/database';
import userPrisma from '../config/user-database';

export class ReviewService {
  async listItems(userId: string, due?: boolean) {
    const where: any = { userId };
    if (due) where.nextReviewAt = { lte: new Date() };
    const items = await userPrisma.reviewItem.findMany({
      where,
      orderBy: { nextReviewAt: 'asc' },
    });
    const questions = await prisma.question.findMany({ where: { id: { in: items.map(item => item.questionId) } } });
    return items.map(item => ({ ...item, question: questions.find(q => q.id === item.questionId) ?? null }));
  }

  async mark(userId: string, itemId: string, correct: boolean) {
    const item = await userPrisma.reviewItem.findFirst({ where: { id: itemId, userId } });
    if (!item) throw Object.assign(new Error('复习项不存在'), { status: 404 });

    // Simplified SM-2 algorithm
    let easeFactor = item.easeFactor;
    let intervalDays = item.intervalDays;
    let status = item.status;
    let reviewCount = item.reviewCount + 1;
    let correctStreak = correct ? item.correctStreak + 1 : 0;
    let wrongCount = correct ? item.wrongCount : item.wrongCount + 1;
    let isWrongAnswer = wrongCount > 0;
    // 答对时更新 lastCorrectAt，用于区分"首次答错"与"多次稳定掌握"
    let lastCorrectAt = correct ? new Date() : item.lastCorrectAt;

    if (correct) {
      if (intervalDays === 0) intervalDays = 1;
      else if (intervalDays === 1) intervalDays = 6;
      else intervalDays = Math.round(intervalDays * easeFactor);
      easeFactor = Math.max(1.3, easeFactor + 0.1);
      if (correctStreak >= 3 && status !== 'mastered') {
        status = status === 'new_' ? 'learning' : status === 'learning' ? 'reviewing' : 'mastered';
      }
    } else {
      intervalDays = 0;
      correctStreak = 0;
      easeFactor = Math.max(1.3, easeFactor - 0.2);
      status = 'learning';
    }

    const nextReviewAt = intervalDays === 0
      ? new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
      : new Date(Date.now() + intervalDays * 24 * 60 * 60 * 1000);

    return (userPrisma.reviewItem as any).update({
      where: { id: itemId, userId },
      data: {
        easeFactor,
        intervalDays,
        status,
        reviewCount,
        correctStreak,
        wrongCount,
        isWrongAnswer,
        lastCorrectAt,
        nextReviewAt,
      },
    });
  }

  async addOrUpsert(userId: string, questionId: string, isWrong: boolean) {
    const question = await prisma.question.findUnique({ where: { id: questionId } });
    if (!question) throw new Error('Question not found');
    return userPrisma.reviewItem.upsert({
      where: { userId_questionId: { userId, questionId } },
      update: {
        isWrongAnswer: isWrong || undefined,
        wrongCount: isWrong ? { increment: 1 } : undefined,
        status: 'learning',
        nextReviewAt: new Date(),
      },
      create: {
        userId,
        questionId,
        level: question.level,
        type: question.type,
        isWrongAnswer: isWrong,
        wrongCount: isWrong ? 1 : 0,
        status: isWrong ? 'learning' : 'new_',
        nextReviewAt: isWrong ? new Date() : new Date(Date.now() + 24 * 60 * 60 * 1000),
      },
    });
  }

  async getDueItems(userId: string) {
    const now = new Date();
    const items = await userPrisma.reviewItem.findMany({
      where: {
        userId,
        OR: [
          { status: 'new_' },
          { nextReviewAt: { lte: now } },
        ],
      },
      orderBy: { nextReviewAt: 'asc' },
    });
    const questions = await prisma.question.findMany({ where: { id: { in: items.map(item => item.questionId) } } });
    return items.map(item => ({ ...item, question: questions.find(q => q.id === item.questionId) ?? null }));
  }
}

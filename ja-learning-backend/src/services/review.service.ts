import prisma from '../config/database';

export class ReviewService {
  async listItems(userId: string, due?: boolean) {
    const where: any = { userId };
    if (due) where.nextReviewAt = { lte: new Date() };
    return prisma.reviewItem.findMany({
      where,
      include: { question: true },
      orderBy: { nextReviewAt: 'asc' },
    });
  }

  async mark(itemId: string, correct: boolean) {
    const item = await prisma.reviewItem.findUnique({ where: { id: itemId } });
    if (!item) throw new Error('Review item not found');

    // Simplified SM-2 algorithm
    let easeFactor = item.easeFactor;
    let intervalDays = item.intervalDays;
    let status = item.status;
    let reviewCount = item.reviewCount + 1;
    let correctStreak = correct ? item.correctStreak + 1 : 0;
    let wrongCount = correct ? item.wrongCount : item.wrongCount + 1;
    let isWrongAnswer = wrongCount > 0;

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

    return prisma.reviewItem.update({
      where: { id: itemId },
      data: {
        easeFactor,
        intervalDays,
        status,
        reviewCount,
        correctStreak,
        wrongCount,
        isWrongAnswer,
        nextReviewAt,
      },
    });
  }

  async addOrUpsert(userId: string, questionId: string, isWrong: boolean) {
    const question = await prisma.question.findUnique({ where: { id: questionId } });
    if (!question) throw new Error('Question not found');
    return prisma.reviewItem.upsert({
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
    return prisma.reviewItem.findMany({
      where: {
        userId,
        OR: [
          { status: 'new_' },
          { nextReviewAt: { lte: now } },
        ],
      },
      include: { question: true },
      orderBy: { nextReviewAt: 'asc' },
    });
  }
}

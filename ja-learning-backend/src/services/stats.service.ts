import prisma from '../config/database';
import userPrisma from '../config/user-database';

export class StatsService {
  async getUserStats(userId: string) {
    const learner = await userPrisma.anonymousLearner.findUnique({ where: { id: userId }, select: { id: true } });
    if (!learner) throw new Error('Learning identity not found');

    // Get all exam records for this user
    const records = await userPrisma.examRecord.findMany({
      where: { userId },
      select: {
        level: true,
        totalQuestions: true,
        correctCount: true,
        score: true,
      },
    });

    // Calculate aggregates
    const totalQuestions = records.reduce((sum, r) => sum + r.totalQuestions, 0);
    const correctCount = records.reduce((sum, r) => sum + r.correctCount, 0);
    const accuracy = totalQuestions > 0 ? correctCount / totalQuestions : 0;

    // Group by level
    const levelStatsMap: Record<string, { questions: number; correct: number; exams: number }> = {};
    for (const record of records) {
      const level = record.level.toLowerCase();
      if (!levelStatsMap[level]) {
        levelStatsMap[level] = { questions: 0, correct: 0, exams: 0 };
      }
      levelStatsMap[level].questions += record.totalQuestions;
      levelStatsMap[level].correct += record.correctCount;
      levelStatsMap[level].exams += 1;
    }

    // Convert to array
    const levelStats = Object.entries(levelStatsMap).map(([level, stats]) => ({
      level,
      totalQuestions: stats.questions,
      correctCount: stats.correct,
      accuracy: stats.questions > 0 ? stats.correct / stats.questions : 0,
      examCount: stats.exams,
    }));

    return {
      totalQuestions,
      correctCount,
      accuracy,
      streakDays: 0,
      currentLevel: 'n5',
      levelStats,
    };
  }

  /**
   * 错题详情统计：题型分布、知识点分布、时间趋势
   * 区分"首次答错"和"多次稳定掌握"
   */
  async getMistakesDetail(userId: string, level?: string) {
    const where: any = { userId, isWrongAnswer: true };
    if (level) where.level = level.toLowerCase();

    const items: any[] = await userPrisma.reviewItem.findMany({
      where,
      orderBy: { wrongCount: 'desc' },
    });
    const questions = await prisma.question.findMany({ where: { id: { in: items.map(item => item.questionId) } } });
    const questionById = new Map(questions.map(q => [q.id, q]));

    // 题型分布
    const typeDistribution: Record<string, number> = {};
    for (const item of items) {
      const type = item.type;
      typeDistribution[type] = (typeDistribution[type] || 0) + 1;
    }

    // 知识点分布（按 vocabularyId / grammarId 分组）
    const knowledgeDistribution: Record<string, { count: number; label: string }> = {};
    for (const item of items) {
      const q: any = questionById.get(item.questionId);
      if (!q) continue;
      const key = q.vocabularyId || q.grammarId || `type:${q.type}`;
      if (!knowledgeDistribution[key]) {
        knowledgeDistribution[key] = { count: 0, label: q.vocabularyId ? '词汇' : q.grammarId ? '语法' : q.type };
      }
      knowledgeDistribution[key].count++;
    }

    // 时间趋势（按月统计错题数）
    const timeTrend: Record<string, number> = {};
    for (const item of items) {
      const month = new Date(item.createdAt).toISOString().slice(0, 7); // YYYY-MM
      timeTrend[month] = (timeTrend[month] || 0) + 1;
    }

    // 区分"首次答错" vs "多次稳定掌握"
    // 首次答错: wrongCount === 1 且 lastCorrectAt 为 null（从未答对过）
    // 多次稳定掌握: correctStreak >= 3 或 lastCorrectAt 存在
    let firstTimeWrong = 0;
    let masteredAfterMistakes = 0;
    for (const item of items) {
      if (item.wrongCount === 1 && !item.lastCorrectAt) {
        firstTimeWrong++;
      } else if (item.correctStreak >= 3 || item.lastCorrectAt) {
        masteredAfterMistakes++;
      }
    }

    return {
      totalMistakes: items.length,
      typeDistribution,
      knowledgeDistribution,
      timeTrend,
      firstTimeWrong,
      masteredAfterMistakes,
      items: items.map((item: any) => ({
        id: item.id,
        questionId: item.questionId,
        type: item.type,
        level: item.level,
        wrongCount: item.wrongCount,
        correctStreak: item.correctStreak,
        lastCorrectAt: item.lastCorrectAt,
        status: item.status,
        question: questionById.get(item.questionId) ? {
          id: item.questionId,
          type: questionById.get(item.questionId)!.type,
          level: questionById.get(item.questionId)!.level,
          content: questionById.get(item.questionId)!.content,
        } : null,
      })),
    };
  }
}

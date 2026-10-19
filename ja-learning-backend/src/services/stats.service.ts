import prisma from '../config/database';

export class StatsService {
  async getUserStats(userId: string) {
    const learner = await prisma.anonymousLearner.findUnique({ where: { id: userId }, select: { id: true } });
    if (!learner) throw new Error('Learning identity not found');

    // Get all exam records for this user
    const records = await prisma.examRecord.findMany({
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
}

import prisma from '../config/database';

export class ExplanationService {
  async getByQuestionId(questionId: string) {
    return prisma.explanation.findUnique({ where: { questionId } });
  }
}

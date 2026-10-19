import { Response } from 'express';
import { randomUUID } from 'crypto';
import jwt from 'jsonwebtoken';
import prisma from '../config/database';
import { config } from '../config/env';
import { AuthRequest } from '../middleware/auth';
import { setSessionCookie } from '../services/session-cookie';
import { run } from './_shared';
import { contentController } from './content.controller';
import { sessionController } from './session.controller';
import { answerController } from './answer.controller';
import { examController } from './exam.controller';

// Re-export shared utilities for backwards compatibility
export { HttpError } from './_shared';

export class LearningController {
  // Auth — anonymous guest session (kept here for route-file stability)
  guest = run(async (req: AuthRequest, res: Response) => {
    let id: string | undefined;
    const cookie = req.headers.cookie
      ?.split(';')
      .map(part => part.trim())
      .find(part => part.startsWith('ja_session='))
      ?.slice('ja_session='.length);
    if (cookie) {
      try {
        const payload = jwt.verify(decodeURIComponent(cookie), config.jwtSecret) as {
          userId?: string;
          kind?: string;
        };
        if (payload.userId && (await prisma.anonymousLearner.findUnique({ where: { id: payload.userId } }))) {
          if (payload.kind === 'account') {
            res.json({ ready: true });
            return;
          }
          id = payload.userId;
        }
      } catch {
        /* Expired cookie receives a new anonymous identity. */
      }
    }
    if (!id) {
      id = randomUUID();
      await prisma.anonymousLearner.create({ data: { id } });
    }
    const token = jwt.sign({ userId: id, kind: 'guest' }, config.jwtSecret, { expiresIn: '365d' });
    setSessionCookie(res, token);
    res.json({ ready: true });
  });

  // Content queries — delegated to ContentController
  catalog = contentController.catalog;
  examPapers = contentController.examPapers;
  funPapers = contentController.funPapers;
  novelLessons = contentController.novelLessons;
  novelLessonById = contentController.novelLessonById;
  materials = contentController.materials;
  materialById = contentController.materialById;
  dashboard = contentController.dashboard;

  // Session management — delegated to SessionController
  startSession = sessionController.startSession;
  getSession = sessionController.getSession;

  // Answer flow — delegated to AnswerController
  submitAnswer = answerController.submitAnswer;
  nextQuestion = answerController.nextQuestion;

  // Exam mode — delegated to ExamController
  sectionAction = examController.sectionAction;

  // Mistakes view (small, kept here)
  mistakes = run(async (req: AuthRequest, res: Response) => {
    const answers = await prisma.learningAnswer.findMany({
      where: {
        isCorrect: false,
        session: {
          userId: req.userId,
          OR: [{ mode: { not: 'exam' } }, { completedAt: { not: null } }],
        },
      },
      orderBy: { answeredAt: 'desc' },
      include: { question: true },
    });
    const es = await prisma.explanation.findMany({
      where: { questionId: { in: answers.map(a => a.questionId) } },
    });
    res.json({
      items: answers.map(a => ({
        ...a,
        question: a.question,
        explanation: es.find(e => e.questionId === a.questionId) ?? null,
      })),
    });
  });
}

export const learningController = new LearningController();

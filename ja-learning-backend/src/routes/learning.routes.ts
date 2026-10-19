import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { learningController } from '../controllers/learning.controller';

const router = Router();

// Public routes (no auth required)
router.post('/guest', learningController.guest);
router.get('/catalog', learningController.catalog);
router.get('/exam-papers', learningController.examPapers);
router.get('/fun-papers', learningController.funPapers);
router.get('/novel-lessons', learningController.novelLessons);
router.get('/novel-lessons/:id', learningController.novelLessonById);
router.get('/materials', learningController.materials);
router.get('/materials/:id', learningController.materialById);

// Protected routes (auth required)
router.use(authMiddleware);
router.get('/dashboard', learningController.dashboard);
router.post('/sessions', learningController.startSession);
router.get('/sessions/:id', learningController.getSession);
router.post('/sessions/:id/answers', learningController.submitAnswer);
router.post('/sessions/:id/next', learningController.nextQuestion);
router.post('/sessions/:id/section', learningController.sectionAction);
router.get('/mistakes', learningController.mistakes);

export default router;

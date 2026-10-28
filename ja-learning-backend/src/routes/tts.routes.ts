import { Router } from 'express';
import { speak } from '../controllers/tts.controller';

const router = Router();

// Public endpoint — no auth middleware.
// POST /api/v1/tts/speak  body: { text: string, voice?: string }
// Returns audio/mpeg stream.
router.post('/speak', speak);

export default router;

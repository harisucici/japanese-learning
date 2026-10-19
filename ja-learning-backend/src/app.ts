import express from 'express';
import path from 'path';
import cors from 'cors';
import morgan from 'morgan';
import { config } from './config/env';

import learningRoutes from './routes/learning.routes';

import authRoutes from './routes/auth.routes';
import questionRoutes from './routes/question.routes';
import recordRoutes from './routes/record.routes';
import reviewRoutes from './routes/review.routes';
import explanationRoutes from './routes/explanation.routes';
import statsRoutes from './routes/stats.routes';

const app = express();

app.use(cors({ origin: (origin, done) => done(null, !origin || config.frontendOrigins.includes(origin)), credentials: true }));
app.use(express.json());
app.use('/api/v1', (_req, res, next) => { res.setHeader('Cache-Control', 'no-store'); next(); });
app.use('/study-assets',express.static(path.join(__dirname,'../data/study-assets')));
app.use('/exam-assets',express.static(path.join(__dirname,'../data/exam-assets')));
app.use(morgan('dev'));

app.use('/api/v1/learning', learningRoutes);

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/questions', questionRoutes);
app.use('/api/v1/records', recordRoutes);
app.use('/api/v1/review', reviewRoutes);
app.use('/api/v1/explanations', explanationRoutes);
app.use('/api/v1/stats', statsRoutes);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

export default app;

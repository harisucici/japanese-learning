import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { RecordService } from '../services/record.service';
import { createRecordSchema } from '../config/validators';

const svc = new RecordService();

export class RecordController {
  async create(req: AuthRequest, res: Response) {
    try {
      const parsed = createRecordSchema.safeParse(req.body);
      if (!parsed.success) return res.status(400).json({ error: parsed.error.flatten() });
      const userId = req.userId!;
      const result = await svc.create(userId, parsed.data);
      res.status(201).json(result);
    } catch (e: any) {
      res.status(e.status || 500).json({ error: e.message });
    }
  }

  async listByUser(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      if (req.params.userId !== userId) return res.status(403).json({ error: 'Forbidden' });
      const records = await svc.listByUser(userId);
      res.json(records);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }

  async getById(req: AuthRequest, res: Response) {
    try {
      const recordId = req.params.id as string;
      const record = await svc.getById(recordId);
      if (!record) return res.status(404).json({ error: 'Record not found' });
      // Verify ownership
      if (record.userId !== req.userId) {
        return res.status(403).json({ error: 'Forbidden' });
      }
      res.json(record);
    } catch (e: any) {
      res.status(500).json({ error: e.message });
    }
  }
}

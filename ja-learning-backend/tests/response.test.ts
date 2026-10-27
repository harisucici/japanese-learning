import express from 'express';
import request from 'supertest';
import { envelopeResponse } from '../src/utils/response';

const app = express();
app.use(envelopeResponse());
app.get('/object', (_req, res) => { res.json({ title: 'test' }); });
app.get('/list', (_req, res) => { res.json({ items: [{ id: 'q1' }], total: 25, limit: 10, offset: 10 }); });
app.get('/page-only', (_req, res) => { res.json({ items: [], total: 25, page: 2 }); });
app.get('/error', (_req, res) => { res.status(400).json({ error: 'Invalid payload', details: { fieldErrors: { title: ['Required'] } } }); });
app.get('/server-error', (_req, res) => { res.status(500).json({ error: 'Internal error' }); });
app.get('/explicit', (_req, res) => { res.json({ success: true, data: null }); });
app.get('/ack', (_req, res) => { res.json({ success: true }); });

describe('API response envelopes', () => {
  it('wraps plain payloads', async () => {
    expect((await request(app).get('/object')).body).toEqual({ success: true, data: { title: 'test' } });
  });
  it('preserves items and total while adding accurate pagination metadata', async () => {
    expect((await request(app).get('/list')).body).toEqual({ success: true, data: { items: [{ id: 'q1' }], total: 25, limit: 10, offset: 10 }, meta: { page: 2, limit: 10, total: 25, totalPages: 3 } });
  });
  it('does not infer page size from a page number and total', async () => {
    expect((await request(app).get('/page-only')).body).toEqual({ success: true, data: { items: [], total: 25, page: 2 } });
  });
  it('preserves validation details and maps the HTTP status', async () => {
    expect((await request(app).get('/error')).body).toEqual({ success: false, error: { code: 'INVALID_INPUT', message: 'Invalid payload', details: { fieldErrors: { title: ['Required'] } } } });
  });
  it('uses an internal error code for 500 responses', async () => {
    expect((await request(app).get('/server-error')).body.error.code).toBe('INTERNAL_ERROR');
  });
  it('does not double wrap explicit envelopes or acknowledgments', async () => {
    expect((await request(app).get('/explicit')).body).toEqual({ success: true, data: null });
    expect((await request(app).get('/ack')).body).toEqual({ success: true });
  });
});

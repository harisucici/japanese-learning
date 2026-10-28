import { Request, Response } from 'express';
import { execFile } from 'child_process';
import { promisify } from 'util';

const execFileAsync = promisify(execFile);

const ALLOWED_VOICES = new Set([
  'ja-JP-NanamiNeural',
  'ja-JP-KeitaNeural',
  'ja-JP-ShioriNeural',
]);

const DEFAULT_VOICE = 'ja-JP-NanamiNeural';
const CACHE_LIMIT = 200;

const audioCache = new Map<string, Buffer>();

function cacheGet(key: string): Buffer | null {
  const value = audioCache.get(key);
  if (value === undefined) return null;
  audioCache.delete(key);
  audioCache.set(key, value);
  return value;
}

function cacheSet(key: string, value: Buffer): void {
  if (audioCache.has(key)) audioCache.delete(key);
  audioCache.set(key, value);
  while (audioCache.size > CACHE_LIMIT) {
    const oldest = audioCache.keys().next().value;
    if (oldest === undefined) break;
    audioCache.delete(oldest);
  }
}

async function synthesize(text: string, voice: string): Promise<Buffer> {
  const { stdout } = await execFileAsync(
    'python3',
    ['-m', 'edge_tts', '--text', text, '--voice', voice, '--write-media', '-'],
    { encoding: 'buffer', maxBuffer: 10 * 1024 * 1024 }
  );
  return stdout as unknown as Buffer;
}

export async function speak(req: Request, res: Response): Promise<void> {
  try {
    const { text, voice = DEFAULT_VOICE } = req.body || {};
    if (typeof text !== 'string' || text.length === 0) {
      res.status(400).json({ error: 'text is required' });
      return;
    }
    if (text.length > 500) {
      res.status(400).json({ error: 'text must be 500 characters or fewer' });
      return;
    }
    const selectedVoice = ALLOWED_VOICES.has(voice) ? voice : DEFAULT_VOICE;

    const cacheKey = `${selectedVoice}|${text}`;
    let audio = cacheGet(cacheKey);
    if (!audio) {
      audio = await synthesize(text, selectedVoice);
      cacheSet(cacheKey, audio);
    }

    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Content-Length', String(audio.length));
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.send(audio);
  } catch (err: any) {
    console.error('[TTS] synthesis failed:', err?.message || err);
    if (!res.headersSent) {
      res.status(500).json({ error: 'TTS synthesis failed' });
    }
  }
}

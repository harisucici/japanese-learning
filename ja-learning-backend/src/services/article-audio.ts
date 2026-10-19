import { config } from '../config/env';

// Database rows contain only this object ID; Cloudinary owns all media metadata.
export function articleAudio(audioId: string) {
  if (!/^audio-\d{3}$/.test(audioId)) throw new Error(`Invalid audio object ID: ${audioId}`);
  const base = config.audioPublicBaseUrl.replace(/\/$/, '');
  if (!base) throw new Error('AUDIO_PUBLIC_BASE_URL is not configured');
  return {
    id: audioId,
    title: '文章配套音频',
    url: `${base}/${audioId}.mp3`,
  };
}

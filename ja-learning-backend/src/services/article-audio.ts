import { config } from '../config/env';

// Database rows contain only this object ID; Cloudinary owns all media metadata.
// 支持两种音频 ID 格式：audio-001 到 audio-100（附赠100篇）和 short-audio-101 到 short-audio-201（短文PDF）
const AUDIO_ID_PATTERNS = [
  /^audio-(\d{3})$/,        // audio-001 格式
  /^short-audio-(\d{3})$/,  // short-audio-101 格式
];

export function articleAudio(audioId: string) {
  // 验证音频 ID 格式
  let isValid = false;
  for (const pattern of AUDIO_ID_PATTERNS) {
    if (pattern.test(audioId)) {
      isValid = true;
      break;
    }
  }
  if (!isValid) {
    throw new Error(`Invalid audio object ID: ${audioId}`);
  }

  const base = config.audioPublicBaseUrl.replace(/\/$/, '');
  if (!base) throw new Error('AUDIO_PUBLIC_BASE_URL is not configured');
  return {
    id: audioId,
    title: '文章配套音频',
    url: `${base}/${audioId}.mp3`,
  };
}

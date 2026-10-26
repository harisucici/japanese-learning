import dotenv from 'dotenv';
dotenv.config();

const jwtSecret = process.env.JWT_SECRET;
if (!jwtSecret && process.env.NODE_ENV === 'production') {
  throw new Error('JWT_SECRET is required in production');
}

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  jwtSecret: jwtSecret || 'dev-secret-only',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  nodeEnv: process.env.NODE_ENV || 'development',
  tursoUrl: process.env.TURSO_URL || '',
  tursoAuthToken: process.env.TURSO_AUTH_TOKEN || '',
  userTursoUrl: process.env.USER_TURSO_URL || '',
  userTursoAuthToken: process.env.USER_TURSO_AUTH_TOKEN || '',
  userRegistrationEnabled: process.env.ENABLE_USER_REGISTRATION !== 'false',
  passwordResetApiKey: process.env.PASSWORD_RESET_API_KEY || '',
  passwordResetFrom: process.env.PASSWORD_RESET_FROM || '',
  publicAppUrl: process.env.PUBLIC_APP_URL || '',
  audioPublicBaseUrl: process.env.AUDIO_PUBLIC_BASE_URL || (process.env.CLOUDINARY_CLOUD_NAME ? `https://res.cloudinary.com/${process.env.CLOUDINARY_CLOUD_NAME}/video/upload/ja-learning/audio` : ''),
  frontendOrigins: (process.env.FRONTEND_ORIGINS || 'http://localhost:4173,http://localhost:5173,http://localhost:8080').split(',').map(origin => origin.trim()).filter(Boolean),
  databaseUrl: process.env.DATABASE_URL || 'file:./dev.db',
  serveFrontend: process.env.SERVE_FRONTEND === 'true' || (process.env.SERVE_FRONTEND === undefined && process.env.NODE_ENV === 'production'),
};

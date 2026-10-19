import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  jwtSecret: process.env.JWT_SECRET || 'default-secret',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  nodeEnv: process.env.NODE_ENV || 'development',
  tursoUrl: process.env.TURSO_URL || '',
  tursoAuthToken: process.env.TURSO_AUTH_TOKEN || '',
  databaseUrl: process.env.DATABASE_URL || 'file:./dev.db',
};

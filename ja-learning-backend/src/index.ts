import app from './app';
import { config } from './config/env';
import { verifyDatabaseConnection } from './config/database';

const PORT = config.port;

verifyDatabaseConnection()
  .then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT} [${config.nodeEnv}]`);
    });
  })
  .catch((err) => {
    console.error('Database connection failed, refusing to start:', err.message);
    process.exit(1);
  });

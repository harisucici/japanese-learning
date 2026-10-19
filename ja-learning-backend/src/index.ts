import app from './app';
import { config } from './config/env';

const PORT = config.port;

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Server running on http://localhost:${PORT} [${config.nodeEnv}]`);
});

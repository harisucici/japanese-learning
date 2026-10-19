import app from './app';
import { config } from './config/env';

const PORT = config.port;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT} [${config.nodeEnv}]`);
});

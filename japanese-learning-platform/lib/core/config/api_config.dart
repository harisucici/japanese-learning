/// API 配置
///
/// 通过环境变量 `API_BASE_URL` 配置后端地址，
/// 默认使用开发环境地址 `http://localhost:3002/api/v1`。
library;

/// API 基础 URL
///
/// 可通过 `--dart-define=API_BASE_URL=<url>` 覆盖，
/// 例如生产环境：
/// ```bash
/// flutter build apk --dart-define=API_BASE_URL=https://api.japanese-learning.app
/// ```
const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3002/api/v1',
);

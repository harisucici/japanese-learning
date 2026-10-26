#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
npm ci --include=dev --prefix ja-learning-platform
npm run build --prefix ja-learning-platform
npm ci --include=dev --prefix ja-learning-backend
npm run build --prefix ja-learning-backend

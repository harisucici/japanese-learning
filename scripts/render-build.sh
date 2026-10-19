#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
export npm_config_cache="${npm_config_cache:-/tmp/ja-learning-render-npm-cache}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/ja-learning-render-xdg-cache}"
npm ci --include=dev --prefix ja-learning-backend
npm ci --include=dev --prefix ja-learning-platform
npm run prisma:generate --prefix ja-learning-backend
npm run build --prefix ja-learning-backend
npm run build --prefix ja-learning-platform

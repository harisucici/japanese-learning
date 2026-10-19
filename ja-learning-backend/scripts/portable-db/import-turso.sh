#!/usr/bin/env bash
set -euo pipefail
if [[ $# -ne 1 ]]; then echo 'Usage: bash import-turso.sh NEW_DATABASE_NAME' >&2; exit 2; fi
if [[ ! "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then echo 'Use a lowercase database name with digits/hyphens.' >&2; exit 2; fi
bundle_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
command -v turso >/dev/null || { echo 'Install the official Turso CLI and run turso auth login first.' >&2; exit 1; }
python3 "$bundle_dir/verify.py" "$bundle_dir/learning.sqlite" "$bundle_dir/manifest.json"
# Creates a new database; never destroys or replaces an existing remote database.
turso db create "$1" --from-file "$bundle_dir/learning.sqlite"
turso db shell "$1" 'SELECT count(*) AS questions FROM Question; SELECT count(*) AS materials FROM StudyMaterial; SELECT count(*) AS files FROM Asset;'

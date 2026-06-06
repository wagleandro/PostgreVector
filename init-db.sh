#!/bin/sh
set -e

export PGRST_SERVER_PORT="${PGRST_SERVER_PORT:-${PORT:-10000}}"

if [ -n "${PGRST_DB_URI:-}" ] && [ -f /etc/postgrest/init-db.sql ]; then
  echo "Initializing PostgREST database..."
  until psql "$PGRST_DB_URI" -v ON_ERROR_STOP=1 -f /etc/postgrest/init-db.sql; do
    echo "Database not ready, retrying in 3 seconds..."
    sleep 3
  done
fi

exec postgrest /etc/postgrest.conf

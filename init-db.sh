#!/bin/sh
set -e

export PGRST_SERVER_PORT="${PGRST_SERVER_PORT:-${PORT:-10000}}"

# Wait for PGRST_DB_URI to be available (Render injects it)
RETRY_COUNT=0
MAX_RETRIES=30
while [ -z "${PGRST_DB_URI:-}" ] && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  echo "Waiting for PGRST_DB_URI to be set... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
  sleep 2
  RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ -z "${PGRST_DB_URI:-}" ]; then
  echo "ERROR: PGRST_DB_URI environment variable not set after 60 seconds"
  exit 1
fi

echo "PGRST_DB_URI is set, initializing database if needed..."

if [ -f /etc/postgrest/init-db.sql ]; then
  echo "Running database initialization script..."
  until psql "$PGRST_DB_URI" -v ON_ERROR_STOP=1 -f /etc/postgrest/init-db.sql; do
    echo "Database not ready, retrying in 3 seconds..."
    sleep 3
  done
fi

echo "Starting PostgREST on port $PGRST_SERVER_PORT..."
exec postgrest /etc/postgrest.conf --db-uri "$PGRST_DB_URI" --server-port "$PGRST_SERVER_PORT"

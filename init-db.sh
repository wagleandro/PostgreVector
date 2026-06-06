#!/bin/sh
set -e

echo "=== Environment Variables Available ==="
env | grep -i postgres || echo "No POSTGRES vars found"
env | grep -i db || echo "No DB vars found"
env | grep -i pgrst || echo "No PGRST vars found"
echo "======================================="

export PGRST_SERVER_PORT="${PGRST_SERVER_PORT:-${PORT:-10000}}"

# Wait for database URI to be available (Render injects it)
RETRY_COUNT=0
MAX_RETRIES=30
DB_URI=""

while [ -z "$DB_URI" ] && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # Try multiple possible variable names
  DB_URI="${PGRST_DB_URI:-${DATABASE_URL:-${POSTGRES_CONNECTION_STRING:-}}}"
  
  if [ -z "$DB_URI" ]; then
    echo "Waiting for database URI to be set... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT + 1))
  fi
done

if [ -z "$DB_URI" ]; then
  echo "ERROR: No database URI found in environment variables (checked PGRST_DB_URI, DATABASE_URL, POSTGRES_CONNECTION_STRING)"
  echo "Available env vars:"
  env | sort
  exit 1
fi

export PGRST_DB_URI="$DB_URI"
echo "Database URI found: $(echo $DB_URI | sed 's/:\/\/.*@/:\/\/*****@/')"

if [ -f /etc/postgrest/init-db.sql ]; then
  echo "Running database initialization script..."
  until psql "$PGRST_DB_URI" -v ON_ERROR_STOP=1 -f /etc/postgrest/init-db.sql; do
    echo "Database not ready, retrying in 3 seconds..."
    sleep 3
  done
fi

echo "Starting PostgREST on port $PGRST_SERVER_PORT..."
exec postgrest /etc/postgrest.conf --db-uri "$PGRST_DB_URI" --server-port "$PGRST_SERVER_PORT"

#!/bin/sh
set -e

echo "=== Checking for database connection variables ==="
env | grep -i 'database\|postgres\|pgrst\|sql' | sort || echo "No database-related vars"
echo "=================================================="

export PGRST_SERVER_PORT="${PGRST_SERVER_PORT:-${PORT:-10000}}"
echo "Server port set to: $PGRST_SERVER_PORT"

# Wait for database URI to be available
RETRY_COUNT=0
MAX_RETRIES=30
DB_URI=""

while [ -z "$DB_URI" ] && [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # Try multiple possible variable names that Render might use
  DB_URI="${PGRST_DB_URI:-${DATABASE_URL:-${POSTGRES_URL:-${RENDER_DATABASE_URL:-}}}}"
  
  if [ -z "$DB_URI" ]; then
    echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES: Waiting for database URI..."
    sleep 2
    RETRY_COUNT=$((RETRY_COUNT + 1))
  fi
done

if [ -z "$DB_URI" ]; then
  echo "ERROR: Database URI not found in any expected variable:"
  echo "  - PGRST_DB_URI"
  echo "  - DATABASE_URL"
  echo "  - POSTGRES_URL"
  echo "  - RENDER_DATABASE_URL"
  echo ""
  echo "All environment variables:"
  env | sort
  exit 1
fi

export PGRST_DB_URI="$DB_URI"
echo "Database URI configured (password masked): $(echo $DB_URI | sed 's/:\/\/[^@]*@/:\/\/*****@/')"

if [ -f /etc/postgrest/init-db.sql ]; then
  echo "Running database initialization..."
  until psql "$PGRST_DB_URI" -v ON_ERROR_STOP=1 -f /etc/postgrest/init-db.sql; do
    echo "Database connection failed, retrying in 3 seconds..."
    sleep 3
  done
  echo "Database initialized successfully"
fi

echo "Starting PostgREST server..."
exec postgrest /etc/postgrest.conf --db-uri "$PGRST_DB_URI" --server-port "$PGRST_SERVER_PORT"

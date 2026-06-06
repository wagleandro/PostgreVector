#!/bin/sh
set -e

echo "=== PostgREST Startup ==="
echo "Server port: ${PORT:-10000}"

export PGRST_SERVER_PORT="${PGRST_SERVER_PORT:-${PORT:-10000}}"

# Check if database URI is configured
if [ -z "${PGRST_DB_URI:-}" ]; then
  echo ""
  echo "⚠️  WARNING: PGRST_DB_URI not configured!"
  echo ""
  echo "This service requires a PostgreSQL database to function."
  echo "To set it up:"
  echo ""
  echo "1. Create a PostgreSQL database in Render"
  echo "2. Copy the connection string (postgresql://...)"
  echo "3. Add PGRST_DB_URI environment variable to this web service"
  echo "4. Restart the service"
  echo ""
  echo "For now, PostgREST will start but won't be able to serve requests."
  echo ""
else
  echo "Database URI configured: $(echo $PGRST_DB_URI | sed 's/:\/\/[^@]*@/:\/\/*****@/')"
  
  # Try to initialize database schema if configured
  if [ -f /etc/postgrest/init-db.sql ]; then
    echo "Attempting to run initialization script..."
    if psql "$PGRST_DB_URI" -v ON_ERROR_STOP=1 -f /etc/postgrest/init-db.sql 2>/dev/null; then
      echo "Database initialized successfully"
    else
      echo "Database initialization failed (will retry when service is restarted)"
    fi
  fi
fi

echo "Starting PostgREST on port $PGRST_SERVER_PORT..."
exec postgrest /etc/postgrest.conf

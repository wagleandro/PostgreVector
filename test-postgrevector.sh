#!/usr/bin/env bash
set -euo pipefail

cleanup=false
if [[ ${1:-} == "--cleanup" ]]; then
  cleanup=true
fi

echo "=== PostgreVector Docker verification ==="

docker compose up --build --detach

echo "Waiting for postgres_vector health..."
end=$((SECONDS + 120))
while true; do
  status=$(docker inspect --format='{{.State.Health.Status}}' postgres_vector 2>/dev/null || echo "unknown")
  echo "  postgres_vector health: ${status}"
  if [[ "$status" == "healthy" ]]; then
    break
  fi
  if [[ "$status" == "unhealthy" ]]; then
    echo "Postgres container is unhealthy. Printing logs..."
    docker compose logs postgres --no-color
    exit 1
  fi
  if (( SECONDS >= end )); then
    echo "Timed out waiting for postgres_vector health. Printing logs..."
    docker compose logs postgres --no-color
    exit 1
  fi
  sleep 5
done

echo "Checking vector extension..."
vector_ext=$(docker exec postgres_vector psql -U postgres -d appdb -tA -c "SELECT extname FROM pg_extension WHERE extname='vector';" || true)
if [[ -z "${vector_ext:-}" ]] || [[ "$vector_ext" != "vector" ]]; then
  echo "ERROR: vector extension not found."
  docker compose logs postgres --no-color
  exit 1
fi

echo "Checking health_check table..."
health=$(docker exec postgres_vector psql -U postgres -d appdb -tA -c "SELECT id || ':' || status FROM health_check WHERE id = 1;")
if [[ "$health" != "1:ok" ]]; then
  echo "ERROR: health_check row is not valid or not available: ${health}"
  docker compose logs postgres --no-color
  exit 1
fi

echo "Testing PostgREST endpoint from inside postgrest_api..."
response=$(docker exec postgrest_api curl -sSf http://localhost:10000/health_check || true)
if [[ -z "$response" ]] || ! echo "$response" | grep -q '"status"'; then
  echo "ERROR: failed to fetch health_check from PostgREST."
  echo "Response was: $response"
  docker compose logs postgrest --no-color
  exit 1
fi

echo "PostgREST response:"
echo "$response"

echo "=== Verification completed successfully ==="
if [[ "$cleanup" == true ]]; then
  echo "Cleaning up Docker Compose resources..."
  docker compose down --volumes
fi

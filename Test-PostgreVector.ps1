<#
.SYNOPSIS
Verifica a configuração local do PostgreVector em Docker Compose.

.DESCRIPTION
Este script sobe os containers, aguarda o estado saudável do Postgres,
verifica a extensão pgvector, testa a tabela health_check e confirma que
PostgREST responde.

.PARAMETER Cleanup
Remove os containers e volumes ao final do teste.
#>

param(
    [switch]$Cleanup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host '=== PostgreVector Docker verification ==='

docker compose up --build --detach | Out-Null

Write-Host 'Waiting for postgres_vector health...'
$timeout = (Get-Date).AddSeconds(120)

while ($true) {
    $status = docker inspect --format='{{.State.Health.Status}}' postgres_vector 2>$null
    if (-not $status) { $status = 'unknown' }
    Write-Host "  postgres_vector health: $status"
    if ($status -eq 'healthy') { break }
    if ($status -eq 'unhealthy') {
        Write-Host 'Postgres container is unhealthy. Printing logs...'
        docker compose logs postgres --no-color
        throw 'Postgres container is unhealthy.'
    }
    if ((Get-Date) -ge $timeout) {
        Write-Host 'Timed out waiting for postgres_vector health. Printing logs...'
        docker compose logs postgres --no-color
        throw 'Timed out waiting for postgres_container health.'
    }
    Start-Sleep -Seconds 5
}

Write-Host 'Checking vector extension...'
$vectorExt = docker exec postgres_vector psql -U postgres -d appdb -tA -c "SELECT extname FROM pg_extension WHERE extname='vector';" 2>$null
if ([string]::IsNullOrWhiteSpace($vectorExt) -or $vectorExt.Trim() -ne 'vector') {
    Write-Host 'ERROR: vector extension not found.'
    docker compose logs postgres --no-color
    throw 'vector extension missing.'
}

Write-Host 'Checking health_check table...'
$health = docker exec postgres_vector psql -U postgres -d appdb -tA -c "SELECT id || ':' || status FROM health_check WHERE id = 1;"
if ($health.Trim() -ne '1:ok') {
    Write-Host "ERROR: health_check row is not valid or not available: $health"
    docker compose logs postgres --no-color
    throw 'health_check verification failed.'
}

Write-Host 'Testing PostgREST endpoint from inside postgrest_api...'
$response = docker exec postgrest_api curl -sSf http://localhost:10000/health_check 2>$null
if ([string]::IsNullOrWhiteSpace($response) -or -not ($response -match '"status"')) {
    Write-Host 'ERROR: failed to fetch health_check from PostgREST.'
    Write-Host "Response was: $response"
    docker compose logs postgrest --no-color
    throw 'PostgREST endpoint verification failed.'
}

Write-Host 'PostgREST response:'
Write-Host $response
Write-Host '=== Verification completed successfully ==='

if ($Cleanup) {
    Write-Host 'Cleaning up Docker Compose resources...'
    docker compose down --volumes | Out-Null
}

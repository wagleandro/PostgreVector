# Render Deployment Setup

## Overview

This project is configured for deployment on [Render](https://render.com) with:
- **Web Service**: PostgREST API (Docker-based)
- **Database**: PostgreSQL with pgvector extension

## Deployment Steps

### 1. Create PostgreSQL Database on Render

1. Go to https://dashboard.render.com
2. Click **+ New** → **PostgreSQL**
3. Configure:
   - **Name**: `postgrevector-db`
   - **Database**: `appdb`
   - **Region**: `oregon` (same as web service for faster connection)
   - **PostgreSQL Version**: `15`
4. Click **Create Database**
5. Wait for the database to be provisioned (takes a few minutes)

### 2. Get Connection String

1. Navigate to your PostgreSQL database in Render Dashboard
2. Copy the **Internal Database URL** (looks like: `postgresql://user:password@host:5432/appdb`)
3. This is your `PGRST_DB_URI`

### 3. Add Environment Variable to Web Service

1. Go to your `postgrest-api` web service
2. Go to **Environment** tab
3. Find or create the `PGRST_DB_URI` environment variable
4. Paste the connection string from step 2
5. Click **Save Changes**
6. Service will automatically redeploy with the new variable

### 4. Deploy

Push changes to your repository:

```bash
git add .
git commit -m "Configure for Render deployment"
git push origin main
```

The web service will auto-deploy via the `autoDeployTrigger: commit` in `render.yaml`.

### 5. Verify

Once deployed:
- Check service logs in Render Dashboard
- Look for: `"API server listening on 0.0.0.0:10000"`
- Test the API:
  ```bash
  curl https://postgrevector.onrender.com/
  ```

## Troubleshooting

### Service won't start
- Check that `PGRST_DB_URI` is set correctly
- Verify the database is still running in Render Dashboard
- Check service logs for connection errors

### Database connection timeout
- Ensure database and web service are in the **same region**
- Check that the database is accessible from the web service

### 503 Service Unavailable
- PostgREST is still loading schema cache
- Wait a few seconds and retry

## Files

- `render.yaml` - Infrastructure as Code configuration
- `Dockerfile` - Container build instructions
- `postgrest.conf` - PostgREST server configuration
- `init-db.sh` - Database initialization script
- `init-db.sql` - SQL schema setup

## Local Development

For local testing with docker compose:

```bash
docker compose up --build
```

This will start:
- PostgreSQL on `localhost:5432` using `Dockerfile.postgres` with `pgvector`
- PostgREST on `localhost:10000` inside the service
- Caddy reverse proxy on `localhost:80`

Access the API at: http://localhost

For Render, the web service builds from `Dockerfile` and exposes PostgREST on port `10000`.

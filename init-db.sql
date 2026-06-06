-- init-db.sql
-- Este script é idempotente e pode ser executado no banco de dados Render Postgres
-- antes ou durante o início do PostgREST.

-- Cria a role de acesso anônimo usada pelo PostgREST.
DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'web_anon') THEN
    CREATE ROLE web_anon NOLOGIN;
  END IF;
END
$$;



-- Garante o uso do schema público.
GRANT USAGE ON SCHEMA public TO web_anon;

-- Garantir permissões de consulta em todas as tabelas existentes.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO web_anon;

-- Garantir permissão de execução em todas as funções existentes.
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO web_anon;

-- Atribuir privilégios automaticamente a novos objetos criados no futuro.
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO web_anon;

-- Simple health endpoint for Render and local checks.
CREATE TABLE IF NOT EXISTS health_check (
  id INTEGER PRIMARY KEY,
  status TEXT NOT NULL DEFAULT 'ok'
);

INSERT INTO health_check (id, status)
VALUES (1, 'ok')
ON CONFLICT (id) DO UPDATE
  SET status = EXCLUDED.status;

-- Certifique-se de que a extensão pgvector existe (se ainda não existir).
CREATE EXTENSION IF NOT EXISTS pgvector WITH SCHEMA public;

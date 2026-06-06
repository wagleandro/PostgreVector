-- init-db.sql
-- Este script é idempotente e pode ser executado no banco de dados Render Postgres
-- antes ou durante o início do PostgREST.

-- Cria a role de acesso anônimo usada pelo PostgREST.
CREATE ROLE IF NOT EXISTS web_anon NOLOGIN;

-- Garante o uso do schema público.
GRANT USAGE ON SCHEMA public TO web_anon;

-- Garantir permissões de consulta em todas as tabelas existentes.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO web_anon;

-- Garantir permissão de execução em todas as funções existentes.
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO web_anon;

-- Atribuir privilégios automaticamente a novos objetos criados no futuro.
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO web_anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO web_anon;

-- Certifique-se de que a extensão pgvector existe (se ainda não existir).
CREATE EXTENSION IF NOT EXISTS pgvector WITH SCHEMA public;

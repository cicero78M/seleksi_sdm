-- OpenClaw application/RAG database baseline.
-- Internal OpenClaw SQLite databases are intentionally not migrated by this file.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;
CREATE SCHEMA IF NOT EXISTS rag;

CREATE TABLE IF NOT EXISTS rag.documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id text NOT NULL DEFAULT 'default',
  source_uri text NOT NULL,
  source_type text NOT NULL,
  title text,
  content_hash text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','processing','failed','archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, source_uri, content_hash)
);

CREATE TABLE IF NOT EXISTS rag.document_chunks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES rag.documents(id) ON DELETE CASCADE,
  tenant_id text NOT NULL DEFAULT 'default',
  chunk_index integer NOT NULL CHECK (chunk_index >= 0),
  content text NOT NULL,
  token_count integer,
  embedding vector(1536),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (document_id, chunk_index)
);

CREATE TABLE IF NOT EXISTS rag.retrieval_events (
  id bigserial PRIMARY KEY,
  tenant_id text NOT NULL DEFAULT 'default',
  query text NOT NULL,
  strategy text NOT NULL,
  result_count integer NOT NULL DEFAULT 0,
  top_score double precision,
  latency_ms integer,
  model text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS rag.feedback (
  id bigserial PRIMARY KEY,
  retrieval_event_id bigint REFERENCES rag.retrieval_events(id) ON DELETE SET NULL,
  tenant_id text NOT NULL DEFAULT 'default',
  rating smallint CHECK (rating BETWEEN 1 AND 5),
  comment text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS documents_tenant_status_idx ON rag.documents (tenant_id, status);
CREATE INDEX IF NOT EXISTS documents_metadata_gin_idx ON rag.documents USING gin (metadata);
CREATE INDEX IF NOT EXISTS chunks_tenant_idx ON rag.document_chunks (tenant_id);
CREATE INDEX IF NOT EXISTS chunks_document_idx ON rag.document_chunks (document_id, chunk_index);
CREATE INDEX IF NOT EXISTS chunks_content_fts_idx ON rag.document_chunks USING gin (to_tsvector('simple', content));
CREATE INDEX IF NOT EXISTS chunks_embedding_hnsw_idx ON rag.document_chunks USING hnsw (embedding vector_cosine_ops) WHERE embedding IS NOT NULL;
CREATE INDEX IF NOT EXISTS retrieval_events_tenant_time_idx ON rag.retrieval_events (tenant_id, created_at DESC);


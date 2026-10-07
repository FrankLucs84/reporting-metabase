#!/bin/sh
# Crea lo schema e l'utente in sola lettura usato da Metabase.
set -e
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -v ro_password="$METABASE_RO_PASSWORD" <<'SQL'
CREATE SCHEMA IF NOT EXISTS contoso;
CREATE ROLE metabase_ro LOGIN PASSWORD :'ro_password';
GRANT CONNECT ON DATABASE contoso TO metabase_ro;
GRANT USAGE ON SCHEMA contoso TO metabase_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA contoso GRANT SELECT ON TABLES TO metabase_ro;
SQL

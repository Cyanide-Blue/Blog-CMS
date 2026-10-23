#!/bin/sh
set -e
if [ -n "$POSTGRES_EXPORTER_PASSWORD" ]; then
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$\$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'exporter') THEN
        CREATE USER exporter WITH PASSWORD '$POSTGRES_EXPORTER_PASSWORD';
      ELSE
        ALTER USER exporter WITH PASSWORD '$POSTGRES_EXPORTER_PASSWORD';
      END IF;
    END
    \$\$;
    GRANT pg_monitor TO exporter;
EOSQL
fi

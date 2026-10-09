#!/bin/bash
# Runs once, on the first start of an empty postgres volume.
# Creates two databases, each owned by its own non-superuser role:
#   n8n -> n8n internal state (workflows, credentials, executions)
#   app -> business data that workflows read and write
set -euo pipefail

create_db() {
  local db="$1" user="$2" pass="$3"
  echo "Creating role '$user' and database '$db'"
  psql -v ON_ERROR_STOP=1 \
       -v db="$db" -v usr="$user" -v pwd="$pass" \
       --username "$POSTGRES_USER" --dbname postgres <<-'EOSQL'
	CREATE ROLE :"usr" WITH LOGIN PASSWORD :'pwd';
	CREATE DATABASE :"db" OWNER :"usr";
	REVOKE ALL ON DATABASE :"db" FROM PUBLIC;
EOSQL
}

create_db "$N8N_DB" "$N8N_DB_USER" "$N8N_DB_PASSWORD"
create_db "$APP_DB" "$APP_DB_USER" "$APP_DB_PASSWORD"

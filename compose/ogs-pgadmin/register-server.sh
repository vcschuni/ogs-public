#!/usr/bin/env bash
set -e

DB_PATH="/var/lib/pgadmin/pgadmin4.db"
SERVER_NAME="Postgresql Cluster"
HOST="ogs-postgresql-cluster-primary"
PORT=5432
USERNAME="postgres"

if [ -z "${POSTGRES_PASSWORD}" ]; then
  echo "POSTGRES_PASSWORD not set"
  exit 1
fi

# Wait until DB exists (pgAdmin creates it on first run)
until [ -f "$DB_PATH" ]; do
  echo "Waiting for pgAdmin DB..."
  sleep 1
done

echo "Registering server in pgAdmin..."

# Get first user id
USER_ID=$(sqlite3 "$DB_PATH" "select id from user limit 1;")

# Create default server group if missing
GROUP_ID=$(sqlite3 "$DB_PATH" \
  "select id from servergroup where user_id=$USER_ID limit 1;")

if [ -z "$GROUP_ID" ]; then
  sqlite3 "$DB_PATH" \
    "insert into servergroup (name, user_id) values ('Servers', $USER_ID);"
  GROUP_ID=$(sqlite3 "$DB_PATH" \
    "select id from servergroup where user_id=$USER_ID limit 1;")
fi

# Check if server exists
EXISTS=$(sqlite3 "$DB_PATH" \
  "select count(*) from server where name='$SERVER_NAME';")

if [ "$EXISTS" -eq 0 ]; then
  sqlite3 "$DB_PATH" <<EOF
insert into server
(name, host, port, username, password, maintenance_db, ssl_mode, user_id, servergroup_id)
values
('$SERVER_NAME', '$HOST', $PORT, '$USERNAME', '$POSTGRES_PASSWORD', 'postgres', 'prefer', $USER_ID, $GROUP_ID);
EOF
  echo "Server registered."
else
  echo "Server already exists."
fi

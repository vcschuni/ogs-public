#!/bin/sh
set -e

# Start pgAdmin
gunicorn --bind 0.0.0.0:8080 pgadmin4.pgAdmin4:app &
PGADMIN_PID=$!

echo "Waiting for pgadmin4.db to be created..."

# Wait for DB to exist (with timeout)
for i in $(seq 1 60); do
  if [ -f /var/lib/pgadmin/pgadmin4.db ]; then
    echo "pgAdmin DB found."
    break
  fi
  sleep 1
done

# Run server registration
/opt/pgadmin/register-server.sh || true

# Keep container running
wait $PGADMIN_PID

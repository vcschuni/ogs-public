#!/bin/bash

# -----------------------------
# Configuration (from environment)
# -----------------------------
DB_USER="${POSTGRESQL_SUPERUSER_USER:-postgres}"
DB_PASSWORD="${POSTGRESQL_SUPERUSER_PASSWORD}"
DB_HOST="${POSTGRESQL_HOST:-localhost}"
DB_PORT="${POSTGRESQL_PORT:-5432}"

BACKUP_DIR="/backup"
RETENTION_DAYS=14
DATABASES=("postgres" "gisdata")
DATESTAMP=$(date +'%Y%m%d_%H')

# -----------------------------
# Export password for pg_dump
# -----------------------------
export PGPASSWORD="$DB_PASSWORD"

# -----------------------------
# Backup loop
# -----------------------------
for DB_NAME in "${DATABASES[@]}"; do
    BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${DATESTAMP}.dump"
    echo
    echo "Backing up database '${DB_NAME}' to '${BACKUP_FILE}'..."

    # Use TCP connection with host and port
    pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -F c -Z 9 -f "${BACKUP_FILE}"

    if [ $? -eq 0 ]; then
        echo "Backup of '${DB_NAME}' successful."
        echo "To restore this backup:"
        echo "  - log into the pod with access to the database"
        echo "  - pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER -d ${DB_NAME} -v ${BACKUP_FILE}"
    else
        echo "Backup of '${DB_NAME}' failed!"
    fi
done

# -----------------------------
# Cleanup old backups
# -----------------------------
echo
echo "Cleaning up backups older than ${RETENTION_DAYS} days in $BACKUP_DIR..."
find "$BACKUP_DIR" -type f -name "*.dump" -mtime +$RETENTION_DAYS -exec rm -f {} \;
echo "Backup and cleanup completed."
echo

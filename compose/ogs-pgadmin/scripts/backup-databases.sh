#!/bin/bash
set -euo pipefail

# -----------------------------
# Configuration
# -----------------------------
DB_USER="postgres"
DB_PASSWORD="${POSTGRES_PASSWORD}"
DB_HOST="ogs-postgresql-cluster-primary"
DB_PORT=5432
BACKUP_DIR="/backup"
RETENTION_DAYS=14
DATABASES=("postgres" "gisdata" "ogs_configuration")
DATESTAMP=$(date +'%Y%m%d_%H')

# -----------------------------
# Start header
# -----------------------------
START_TS=$(date +"%Y-%m-%d %H:%M:%S %Z")
START_EPOCH=$(date +%s)

echo "========================================"
echo " PostgreSQL Backup Job START"
echo " Start Time : ${START_TS}"
echo " Host       : $(hostname)"
echo "========================================"

# -----------------------------
# Footer (always runs)
# -----------------------------
EXIT_CODE=0
footer() {
    END_TS=$(date +"%Y-%m-%d %H:%M:%S %Z")
    END_EPOCH=$(date +%s)
    DURATION=$((END_EPOCH - START_EPOCH))
    DURATION_FMT=$(printf "%02d:%02d:%02d" $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

    echo
    echo "========================================"
    echo " PostgreSQL Backup Job END"
    echo " End Time   : ${END_TS}"
    echo " Duration   : ${DURATION_FMT}"
    echo " Exit Code  : ${EXIT_CODE}"
    echo "========================================"
    echo
}

trap 'EXIT_CODE=$?; footer' EXIT

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

    # pg_dump with error handling
    if ! pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -F c -Z 9 -f "${BACKUP_FILE}"; then
        echo "Backup of '${DB_NAME}' failed!"
        EXIT_CODE=1
    else
        echo "Backup of '${DB_NAME}' successful."
        echo "To restore this backup:"
        echo " >>> pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER --clean --if-exists -d ${DB_NAME} -v ${BACKUP_FILE}"
    fi
done

# -----------------------------
# Cleanup old backups
# -----------------------------
echo
echo "Cleaning up backups older than ${RETENTION_DAYS} days in $BACKUP_DIR..."
find "$BACKUP_DIR" -type f -name "*.dump" -mtime +$RETENTION_DAYS -exec rm -f {} \;
echo "Backup and cleanup completed."
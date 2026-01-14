#!/bin/bash

# -----------------------------
# Configuration
# -----------------------------
DB_USER="postgres"
BACKUP_DIR="/tmp/database-backups"
RETENTION_DAYS=7
DATABASES=("postgres" "gisdata")
DATESTAMP=$(date +'%Y%m%d_%H')

# -----------------------------
# Prepare backup directory
# -----------------------------
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi

# -----------------------------
# Backup loop
# -----------------------------
for DB_NAME in "${DATABASES[@]}"; do
    BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_backup_${DATESTAMP}.dump"
    echo "Backing up database '${DB_NAME}' to '${BACKUP_FILE}'..."
    
    pg_dump -U "$DB_USER" -d "$DB_NAME" -F c -Z 9 -f "${BACKUP_FILE}"
    
    if [ $? -eq 0 ]; then
        echo "Backup of '${DB_NAME}' successful."
		echo "To restore the database to this backup, do the following:"
		echo "   - log into the OpenShift postgresql pod"
		echo "   - verify that ${BACKUP_FILE} exists"
		echo "   - pg_restore -U postgres -d ${DB_NAME} -v ${BACKUP_FILE}"
    else
        echo "Backup of '${DB_NAME}' failed!"
    fi
done

# -----------------------------
# Cleanup old backups
# -----------------------------
echo "Cleaning up backups older than ${RETENTION_DAYS} days in $BACKUP_DIR..."
find "$BACKUP_DIR" -type f -name "*.dump" -mtime +$RETENTION_DAYS -exec rm -f {} \;

echo "Backup and cleanup completed."

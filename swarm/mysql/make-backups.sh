#!/bin/bash
# backup-cron/backup-script.sh

set -e

# Environment variables
DB_HOST=${DB_HOST:-localhost}
DB_NAME=${DB_NAME:-myapp}
DB_USER=${DB_USER:-dbuser}
DB_PASSWORD=${DB_PASSWORD:-dbpass}
BACKUP_DIR=${BACKUP_DIR:-/backups}
RETENTION_DAYS=${RETENTION_DAYS:-7}

# Create backup filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql.gz"

echo "Starting backup at $(date)"
echo "Database: ${DB_HOST}/${DB_NAME}"

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Perform PostgreSQL backup (adjust for MySQL if needed)
# if command -v pg_dump >/dev/null 2>&1; then
#     echo "Creating PostgreSQL backup..."
#     PGPASSWORD="${DB_PASSWORD}" pg_dump \
#         -h "${DB_HOST}" \
#         -U "${DB_USER}" \
#         -d "${DB_NAME}" \
#         --verbose \
#         --no-password \
#         --format=plain \
#         --no-owner \
#         --no-privileges | gzip > "${BACKUP_FILE}"
# fi

# Alternative MySQL backup (uncomment if using MySQL)
if command -v mysqldump >/dev/null 2>&1; then
    echo "Creating MySQL backup..."
    mysqldump \
        -h "${DB_HOST}" \
        -u "${DB_USER}" \
        -p"${DB_PASSWORD}" \
        --single-transaction \
        --routines \
        --triggers \
        "${DB_NAME}" | gzip > "${BACKUP_FILE}"
fi

# Check if backup was successful
if [ -s "${BACKUP_FILE}" ]; then
    echo "Backup completed successfully: ${BACKUP_FILE}"
    echo "Backup size: $(du -h "${BACKUP_FILE}" | cut -f1)"
    
    # Create a status file for the UI
    echo "{
        \"timestamp\": \"$(date -Iseconds)\",
        \"filename\": \"$(basename "${BACKUP_FILE}")\",
        \"size\": \"$(du -h "${BACKUP_FILE}" | cut -f1)\",
        \"status\": \"success\",
        \"database\": \"${DB_NAME}\"
    }" > "${BACKUP_DIR}/$(basename "${BACKUP_FILE}" .sql.gz).json"
    
else
    echo "Backup failed - file is empty or doesn't exist"
    echo "{
        \"timestamp\": \"$(date -Iseconds)\",
        \"filename\": \"$(basename "${BACKUP_FILE}")\",
        \"size\": \"0B\",
        \"status\": \"failed\",
        \"database\": \"${DB_NAME}\"
    }" > "${BACKUP_DIR}/$(basename "${BACKUP_FILE}" .sql.gz).json"
    exit 1
fi

# Cleanup old backups
echo "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "*.json" -mtime +${RETENTION_DAYS} -delete

echo "Backup process completed at $(date)"

#!/bin/sh

# Constants
S3_ENDPOINT="${AWS_S3_ENDPOINT}"
BUCKET_NAME="${AWS_S3_BUCKET}"
CONFIG_FILE="servers.yaml"
LOG_URL="${LOGGER_URL}"
ISSUER="backup_agent"

# Function to log messages via HTTP POST
log_message() {
    local level="$1"
    local context="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "" >> /var/log/backup-agent.log  # Ensure a new line before the log entry

    # Check if LOG_URL is set
    if [ -n "$LOG_URL" ]; then
        # If LOG_URL is set, send log to the URL via curl
        curl -s -X POST -H "Content-Type: application/json" -d '{
            "timestamp": "'"$timestamp"'",
            "issuer": "'"$ISSUER"'",
            "level": "'"$level"'",
            "type": "Backup",
            "data": {"message": "'"$context"'"}
        }' "$LOG_URL" >> /var/log/backup-agent.log 2>&1
    else
        # If LOG_URL is not set, write log to the backup-agent.log file
        echo "{\"timestamp\": \"$timestamp\", \"issuer\": \"$ISSUER\", \"level\": \"$level\", \"type\": \"Backup\", \"data\": {\"message\": \"$context\"}}" >> /var/log/backup-agent.log
    fi
}

# Get today's date
DATE=$(date +%F)

# Parse servers.yaml and iterate through each server
yq eval '.servers[]' "$CONFIG_FILE" -o=json | jq -c '.' | while read -r SERVER; do

    # Ensure valid data before proceeding
    if [ -z "$SERVER" ]; then
        log_message "error" "No valid data found for server in $CONFIG_FILE"
        continue
    fi

    # Extract details using jq
    HOST=$(echo "$SERVER" | jq -r '.host')
    PORT=$(echo "$SERVER" | jq -r '.port')
    USER=$(echo "$SERVER" | jq -r '.user')
    PASSWORD=$(echo "$SERVER" | jq -r '.password')
    DB=$(echo "$SERVER" | jq -r '.database')
    BACKUP_DIR="/backup/$HOST"
    BACKUP_NAME="$DB-$DATE.sql.gz"
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME"

    # Create a directory for the host
    mkdir -p "$BACKUP_DIR"

    # Run the backup
    log_message "DEBUG" "Starting backup for database $DB on $HOST:$PORT."
    if ! mariadb-dump --skip-ssl -h "$HOST" -P "$PORT" -u "$USER" -p"$PASSWORD" "$DB" | gzip > "$BACKUP_FILE"; then
        log_message "CRITICAL" "Failed to back up database $DB on $HOST:$PORT."
        continue
    fi

    # Check if the backup file exists and is not empty
    if [ ! -s "$BACKUP_FILE" ]; then
        log_message "CRITICAL" "Backup file $BACKUP_FILE is empty or not created for database $DB on $HOST:$PORT."
        continue
    fi

    # Upload to S3
    log_message "DEBUG" "Uploading backup $BACKUP_FILE to S3."
    if ! aws s3 cp "$BACKUP_FILE" "s3://$BUCKET_NAME/$DB/$BACKUP_NAME" --endpoint-url="$S3_ENDPOINT"; then
        log_message "CRITICAL" "Failed to upload backup $BACKUP_FILE to S3."
        continue
    fi
    # Clean up local
    rm -rf "$BACKUP_DIR"

    log_message "CRITICAL" "Backup completed for database $DB on $HOST:$PORT."
done

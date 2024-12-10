FROM alpine:latest

RUN apk add --no-cache bash mysql-client aws-cli yq jq curl

WORKDIR /backup

# Copy crontab file to the cron.d directory
COPY backup-agent/src/crontab /etc/cron.d/crontab

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/crontab

# Apply cron job
RUN crontab /etc/cron.d/crontab
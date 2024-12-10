![ShellCheck](https://github.com/allangallop/mariadb-backup-agent/actions/workflows/shellcheck.yml/badge.svg)

# MariaDB Backup Agent

This is a simple project for automating the backup of MariaDB instances to S3 in a docker microservices environment. It quite simply automates **mariadb-dump** and uploads the resulting gunzip to an S3 bucket.

## Configuration

### Servers
You can define the servers to backup via the *servers.yaml* file

```
servers:
  - host: "instance_address"
    port: 3306
    user: "backup"
    password: "password"
    database: "database_name"

```

### S3 Bucket
The bucket and S3 credentials are supplied via environmental variables defined in the [docker-compose.yaml](src/docker-compose.yaml) file.

| Variable | Description | Example |
|---|---|---|
| AWS_S3_ENDPOINT | The S3 Endpoint | https://s3.eu-west-1.wasabisys.com |
| AWS_S3_BUCKET | The bucket name | mybucket |
| AWS_ACCESS_KEY | The access key  for the S3 bucket |   |
| AWS_SECRET_ACCESS_KEY | The secret for the S3 bucket  |   |
|  LOGGER_URL | (optional) when defined sets the url of the logger-daemon  | http://log-daemon-app:8888/log |

### Logging
Whilst this project traditionally logs to `/var/log/backup-agent.log` it can be configured to work with the [logger-daemon](https://github.com/AllanGallop/rest-log-deamon) for centralised auditing via the NOC.
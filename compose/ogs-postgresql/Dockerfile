FROM docker.io/postgis/postgis:18-3.6

# Install Python and dependencies
RUN apt-get update && apt-get install -y \
	bash \
	rsync \
	ssh \
	nano \
	cron \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set timezone to Pacific (BC)
ENV TZ=America/Vancouver

# Optional: add initialization SQL (runs once on first startup)
COPY initdb.d/*.sql /docker-entrypoint-initdb.d/

# Copy the shell script
COPY initdb.d/create_users.sh /docker-entrypoint-initdb.d/

# Copy backup script
COPY backup-databases.sh /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# Append cron entry
RUN echo "0 5 * * * postgres /opt/scripts/backup-databases.sh >> /tmp/database-backups/db-backup.log 2>&1" >> /etc/crontab

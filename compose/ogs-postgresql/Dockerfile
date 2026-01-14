FROM registry-1.docker.io/bitnami/postgresql:17

# Set timezone to Pacific (BC)
ENV TZ=America/Vancouver

# Optional: add initialization SQL (runs once on first startup)
COPY initdb.d/*.sql /docker-entrypoint-initdb.d/

# Copy the shell script
COPY initdb.d/create_users.sh /docker-entrypoint-initdb.d/


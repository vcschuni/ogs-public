FROM docker.io/postgis/postgis:18-3.6

# Set timezone to Pacific (BC)
ENV TZ=America/Vancouver

# Optional: add initialization SQL (runs once on first startup)
COPY initdb.d/*.sql /docker-entrypoint-initdb.d/

# Copy the shell script
COPY initdb.d/create_users.sh /docker-entrypoint-initdb.d/


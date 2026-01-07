# OpenShift-compatible PostgreSQL 16 with PostGIS
FROM docker.io/bitnami/postgresql-postgis:16

# Optional: add initialization SQL (runs once on first startup)
#COPY initdb.d/*.sql /docker-entrypoint-initdb.d/

# Set timezone (safe, no root required)
ENV TZ=America/Vancouver

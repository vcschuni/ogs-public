# OpenShift-compatible PostgreSQL 16 with PostGIS
FROM docker.io/bitnami/postgresql:latest

# Optional: add initialization SQL (runs once on first startup)
#COPY initdb.d/*.sql /docker-entrypoint-initdb.d/

# Set timezone (safe, no root required)
ENV TZ=America/Vancouver

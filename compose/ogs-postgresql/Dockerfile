# OpenShift-compatible PostgreSQL 16 with PostGIS
FROM docker.io/bitnami/postgresql:latest

# Set timezone to Pacific (BC)
ENV TZ=America/Vancouver
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Optional: add initialization SQL (runs once on first startup)
#COPY initdb.d/*.sql /docker-entrypoint-initdb.d/


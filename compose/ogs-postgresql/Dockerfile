# OpenShift-compatible PostgreSQL 16 with PostGIS
FROM docker.io/bitnami/postgresql:latest

# Install PostGIS, cron, and utilities
RUN apt-get update && apt-get install -y \
    nano \
    postgresql-16-postgis \
    postgis \
    gdal-bin \
    cron \
	tzdata \
    && apt-get clean
	
# Set timezone to Pacific (BC)
ENV TZ=America/Vancouver
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Optional: add initialization SQL (runs once on first startup)
#COPY initdb.d/*.sql /docker-entrypoint-initdb.d/


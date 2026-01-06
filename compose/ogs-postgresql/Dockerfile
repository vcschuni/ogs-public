FROM docker.io/library/postgres:16

# Install PostGIS and utilities
USER root
RUN apt-get update && apt-get install -y \
    postgresql-16-postgis \
    postgis \
    gdal-bin \
    tzdata \
    && apt-get clean

# Set timezone to Pacific (BC)
ENV TZ=America/Vancouver
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create data directory with group write permissions
RUN mkdir -p /var/lib/postgresql/data && chmod -R 777 /var/lib/postgresql/data

# Switch back to postgres user
USER postgres

# Environment
ENV POSTGRES_PASSWORD=password

# Expose Postgres port
EXPOSE 5432

# Use default Postgres entrypoint
CMD ["postgres"]

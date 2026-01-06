FROM postgis/postgis:16-3.4

# Create data directory with open permissions
RUN mkdir -p /var/lib/postgresql/data && \
    chmod 777 /var/lib/postgresql/data

EXPOSE 5432

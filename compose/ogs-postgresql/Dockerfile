FROM postgis/postgis:16-3.4

# Make the data directory group-writable so OpenShift random UID can write
USER root
RUN mkdir -p /var/lib/postgresql/data && chmod -R 777 /var/lib/postgresql/data
USER postgres

EXPOSE 5432
# Use the Crunchy Data OpenShift-friendly pgAdmin4 image
FROM registry.connect.redhat.com/crunchydata/crunchy-pgadmin4:ubi9-9.8-2550

FROM registry.connect.redhat.com/crunchydata/crunchy-pgadmin4:ubi9-9.8-2550

# Set default pgAdmin credentials
ENV PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_SETUP_PASSWORD=password

# Set pgAdmin to listen on port 8080
ENV SERVER_PORT=8080

# Ensure runtime directories are writable by OpenShift random UID
USER root
RUN mkdir -p /run/httpd \
    && chmod -R 777 /run/httpd \
    && chown -R 1001:0 /run/httpd
USER 1001

# Expose the container port
EXPOSE 8080
# Use the Crunchy Data OpenShift-friendly pgAdmin4 image
FROM registry.connect.redhat.com/crunchydata/crunchy-pgadmin4:ubi9-9.8-2550

# Set default pgAdmin credentials
ENV PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_SETUP_PASSWORD=password

# Set pgAdmin to listen on port 8080
ENV SERVER_PORT=8080

# Optional: ensure runtime directories are writable by OpenShift random UID
USER root
RUN mkdir -p /run/httpd && chmod -R 777 /run/httpd
USER 1001  # Crunchy image default non-root UID

# Expose the port
EXPOSE 8080

# Entrypoint is already configured in the base image

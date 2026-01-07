# Crunchy Data pgAdmin4 OpenShift-ready image
FROM registry.connect.redhat.com/crunchydata/crunchy-pgadmin4:ubi9-9.8-2550

# Set default credentials (can be overridden via oc set env)
ENV PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_SETUP_PASSWORD=password

# Server listens internally on port 8080
#ENV SERVER_PORT=8080

USER root
RUN mkdir -p /run/httpd /pgadmin4/volumes
USER 1001

# Expose the container port
EXPOSE 5050

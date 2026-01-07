# Crunchy pgAdmin4 OpenShift-friendly image
FROM registry.connect.redhat.com/crunchydata/crunchy-pgadmin4:ubi9-9.8-2550

# Set pgAdmin credentials (optional, can also use oc set env)
ENV PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_SETUP_PASSWORD=password

# Listen internally on 8080
ENV SERVER_PORT=8080

# Make runtime directories writable by any UID
USER root
RUN mkdir -p /run/httpd /pgadmin4/volumes \
    && chmod -R 777 /run/httpd /pgadmin4/volumes

# Let OpenShift assign the runtime UID automatically
USER 1001

# Expose the container port
EXPOSE 8080

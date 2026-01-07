# Crunchy pgAdmin OpenShift-ready image
FROM registry.connect.redhat.com/crunchydata/crunchy-pgadmin4:ubi9-9.8-2550

# Set default credentials (can be overridden with oc set env)
ENV PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_SETUP_PASSWORD=password

# Server listens internally on 8080
ENV SERVER_PORT=8080

# Make runtime and binary directories fully accessible
USER root
RUN mkdir -p /run/httpd /pgadmin4/volumes \
    && chmod -R 777 /run/httpd /pgadmin4/volumes \
    && chmod -R a+rx /venv/bin /usr/local/bin /usr/bin

# Switch back to non-root user
USER 1001

# Expose the container port
EXPOSE 8080

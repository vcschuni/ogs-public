# Use the official OpenShift-friendly pgAdmin4 image
FROM dpage/pgadmin4:latest

# ----------------------------
# Environment variables
# ----------------------------
ENV PGADMIN_DEFAULT_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_DEFAULT_PASSWORD=password
ENV PGADMIN_CONFIG_FILE=/pgadmin4/volumes/config_local.py
ENV SERVER_PORT=8080
ENV PGADMIN_DATA_DIR=/pgadmin4/volumes

# ----------------------------
# Create runtime volume directory
# ----------------------------
USER root
RUN mkdir -p /pgadmin4/volumes \
    && chmod -R 777 /pgadmin4/volumes
USER 1001

# ----------------------------
# Expose port
# ----------------------------
EXPOSE 8080

# The entrypoint is already defined in the base image
# It will pick up PGADMIN_CONFIG_FILE and PGADMIN_DATA_DIR

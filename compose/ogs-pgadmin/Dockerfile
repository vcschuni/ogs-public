# Use OpenShift-friendly pgAdmin4 image
FROM dpage/pgadmin4:latest

# ----------------------------
# Environment variables
# ----------------------------
ENV PGADMIN_DEFAULT_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_DEFAULT_PASSWORD=password
ENV PGADMIN_DATA_DIR=/pgadmin4/volumes
ENV SERVER_PORT=8080
ENV PGADMIN_CONFIG_FILE=/pgadmin4/volumes/config_local.py

# ----------------------------
# Create writable volume directory
# ----------------------------
USER root
RUN mkdir -p /pgadmin4/volumes \
    && chmod -R 777 /pgadmin4/volumes

# ----------------------------
# Copy config_local.py into the image
# ----------------------------
COPY config_local.py /pgadmin4/volumes/config_local.py
RUN chmod 644 /pgadmin4/volumes/config_local.py

USER 1001

# ----------------------------
# Expose port
# ----------------------------
EXPOSE 8080

# Base image already has an entrypoint that starts pgAdmin

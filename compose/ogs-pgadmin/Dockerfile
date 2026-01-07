# Base image with Python 3.9
FROM registry.access.redhat.com/ubi9/python-39:latest

USER root

# ----------------------------
# Create runtime directories (OpenShift random UID safe)
# ----------------------------
RUN mkdir -p /pgadmin4/volumes /run/httpd \
    && chmod -R 777 /pgadmin4/volumes /run/httpd

# ----------------------------
# Install pgAdmin4 and Gunicorn
# ----------------------------
RUN pip install --no-cache-dir pgadmin4 gunicorn

# ----------------------------
# Copy Python entrypoint wrapper and config
# ----------------------------
COPY entrypoint.py /pgadmin4/entrypoint.py
COPY config_local.py /pgadmin4/volumes/config_local.py

# ----------------------------
# Environment variables
# ----------------------------
ENV PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_SETUP_PASSWORD=password
ENV PGADMIN_LISTEN_PORT=8080
ENV PGADMIN_CONFIG_FILE=/pgadmin4/volumes/config_local.py
ENV PGADMIN_STORAGE_DIR=/pgadmin4/volumes

EXPOSE 8080

# ----------------------------
# Run as non-root (OpenShift random UID safe)
# ----------------------------
USER 1001

# ----------------------------
# Start pgAdmin using Gunicorn with the wrapper
# ----------------------------
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "entrypoint:application"]

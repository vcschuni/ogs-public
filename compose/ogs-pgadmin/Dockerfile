# Base image with Python 3.9 preinstalled
FROM registry.access.redhat.com/ubi9/python-39:latest

USER root

# ----------------------------
# Create runtime directories
# ----------------------------
# /pgadmin4/volumes -> writable storage for SQLite DB and sessions
# /run/httpd -> runtime for web server
RUN mkdir -p /pgadmin4/volumes /run/httpd \
    && chmod -R 777 /pgadmin4/volumes /run/httpd

# ----------------------------
# Python environment
# ----------------------------
ENV PATH="/usr/local/bin:$PATH"

# Install Gunicorn and pgAdmin4
RUN pip install --no-cache-dir pgadmin4 gunicorn

# ----------------------------
# Default login credentials
# ----------------------------
ENV PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_SETUP_PASSWORD=password

# Listen on port 8080
ENV PGADMIN_LISTEN_PORT=8080
EXPOSE 8080

# ----------------------------
# SQLite override for OpenShift random UID
# ----------------------------
# pgAdmin tries to write to /var/lib/pgadmin by default, which fails
# We override SQLITE_PATH to use the writable volumes directory
COPY config_local.py /pgadmin4/volumes/config_local.py
ENV PGADMIN_CONFIG_FILE=/pgadmin4/volumes/config_local.py
ENV PGADMIN_STORAGE_DIR=/pgadmin4/volumes

# ----------------------------
# Run as non-root (OpenShift random UID safe)
# ----------------------------
USER 1001

# ----------------------------
# Start pgAdmin using Gunicorn
# ----------------------------
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "pgadmin4.pgAdmin4:app"]

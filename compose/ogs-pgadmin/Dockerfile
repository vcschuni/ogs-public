# Base UBI 9 minimal for OpenShift compatibility
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.3

# Install Python 3 and required utilities
USER root
RUN microdnf install -y python39 python39-pip python39-venv \
    && microdnf clean all

# Create directories for pgAdmin runtime and config
RUN mkdir -p /pgadmin4/volumes /run/httpd

# Make them writable by any UID
RUN chmod -R 777 /pgadmin4/volumes /run/httpd

# Create a Python virtual environment for pgAdmin
RUN python3 -m venv /pgadmin4/venv
ENV PATH="/pgadmin4/venv/bin:$PATH"

# Install pgAdmin4 and Gunicorn
RUN pip install --no-cache-dir pgadmin4 gunicorn

# Set environment variables for default login
ENV PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_SETUP_PASSWORD=password
ENV PGADMIN_LISTEN_PORT=8080

# Expose the desired port
EXPOSE 8080

# Set runtime directories
ENV PGADMIN_CONFIG_FILE=/pgadmin4/volumes/config.py
ENV PGADMIN_STORAGE_DIR=/pgadmin4/volumes

# Switch to non-root user (OpenShift random UID compatible)
USER 1001

# Start pgAdmin using Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "pgadmin4.pgAdmin4:app"]

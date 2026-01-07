# Base image with Python 3.9 preinstalled
FROM registry.access.redhat.com/ubi9/python-39:latest

USER root

# Create directories for pgAdmin runtime and config
RUN mkdir -p /pgadmin4/volumes /run/httpd \
    && chmod -R 777 /pgadmin4/volumes /run/httpd

# Set PATH (python already in base)
ENV PATH="/usr/local/bin:$PATH"

# Install Gunicorn and pgAdmin4
RUN pip install --no-cache-dir pgadmin4 gunicorn

# Default credentials
ENV PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca
ENV PGADMIN_SETUP_PASSWORD=password

# Expose port 8080
ENV PGADMIN_LISTEN_PORT=8080
EXPOSE 8080

# Runtime directories
ENV PGADMIN_CONFIG_FILE=/pgadmin4/volumes/config.py
ENV PGADMIN_STORAGE_DIR=/pgadmin4/volumes

# Switch to non-root user (OpenShift safe)
USER 1001

# Start pgAdmin
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "pgadmin4.pgAdmin4:app"]

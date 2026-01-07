# Start from Debian slim
FROM debian:bullseye-slim

USER root

# Install Python and dependencies
RUN apt-get update && apt-get install -y \
    python3.9 python3.9-venv python3-pip \
    libpq-dev build-essential \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create directories
#RUN mkdir -p /pgadmin4/volumes /opt/pgadmin && chmod -R 777 /pgadmin4/volumes

# Create virtual environment and install pgAdmin4 + Gunicorn
RUN python3.9 -m venv /opt/pgadmin/venv \
    && /opt/pgadmin/venv/bin/pip install --upgrade pip \
    && /opt/pgadmin/venv/bin/pip install pgadmin4 gunicorn

# Set environment variables
#ENV PGADMIN_DEFAULT_EMAIL=volker.schunicht@gov.bc.ca
#ENV PGADMIN_DEFAULT_PASSWORD=password
#ENV PGADMIN_DATA_DIR=/pgadmin4/volumes
#ENV PGADMIN_CONFIG_FILE=/pgadmin4/volumes/config_local.py
#ENV SERVER_PORT=8080
ENV PATH="/opt/pgadmin/venv/bin:$PATH"

# Copy config_local.py into image
#COPY config_local.py /pgadmin4/volumes/config_local.py
#RUN chmod 644 /pgadmin4/volumes/config_local.py

# Expose port
EXPOSE 8080

# Run as non-root OpenShift UID
USER 1001

# Start pgAdmin with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "pgadmin4.pgAdmin4:app"]

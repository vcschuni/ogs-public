# Start from Debian slim
FROM docker.io/debian:bullseye-slim

# Install Python and dependencies
RUN apt-get update && apt-get install -y \
    python3.9 python3.9-venv python3-pip \
    libpq-dev build-essential \
    curl \
	bash \
	rsync \
	ssh \
	nano \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create virtual environment and install pgAdmin4 + Gunicorn
RUN python3.9 -m venv /opt/pgadmin/venv \
    && /opt/pgadmin/venv/bin/pip install --upgrade pip \
    && /opt/pgadmin/venv/bin/pip install pgadmin4 gunicorn

# pgAdmin overrides
RUN echo "LOG_FILE = '/tmp/pgadmin.log'" > /opt/pgadmin/venv/lib/python3.9/site-packages/pgadmin4/config_local.py

# Set environment variables
ENV PATH="/opt/pgadmin/venv/bin:$PATH"
ENV SCRIPT_NAME=/pgadmin
ENV PGADMIN_CONFIG_PROXY_X_FOR_COUNT=1
ENV PGADMIN_LISTEN_PORT=8080
ENV PGADMIN_SERVER_MODE=True 

# Expose port
EXPOSE 8080

# Start pgAdmin with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "pgadmin4.pgAdmin4:app"]

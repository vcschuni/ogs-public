# Start from Debian slim
FROM debian:bullseye-slim

USER root

# Install Python and dependencies
RUN apt-get update && apt-get install -y \
    python3.9 python3.9-venv python3-pip \
    libpq-dev build-essential \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create virtual environment and install pgAdmin4 + Gunicorn
RUN python3.9 -m venv /opt/pgadmin/venv \
    && /opt/pgadmin/venv/bin/pip install --upgrade pip \
    && /opt/pgadmin/venv/bin/pip install pgadmin4 gunicorn

# Set environment variables
ENV PATH="/opt/pgadmin/venv/bin:$PATH"

# Expose port
EXPOSE 8080

# Run as non-root OpenShift UID
USER 1001

# Start pgAdmin with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "pgadmin4.pgAdmin4:app"]

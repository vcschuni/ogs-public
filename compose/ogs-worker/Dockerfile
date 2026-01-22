# Start from Debian slim
FROM docker.io/debian:bullseye-slim

# Install Python and dependencies
RUN apt-get update && apt-get install -y \
	postgresql \
	postgis \
	osm2pgsql \
    curl \
	bash \
	rsync \
	ssh \
	nano \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create scripts directory
RUN mkdir -p /scripts

# Copy scripts and set permissions
COPY scripts/* /scripts/
RUN chmod -R 777 /scripts

# Set working directory
WORKDIR /scripts

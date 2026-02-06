FROM docker.io/postgis/postgis:17-3.6

# Install Python and dependencies
RUN apt-get update && apt-get install -y \
	bash \
	rsync \
	ssh \
	nano \
	cron \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set timezone to Pacific (BC)
ENV TZ=America/Vancouver

# Copy initialization scripts
COPY initdb.d/*.* /docker-entrypoint-initdb.d/

# Copy scripts and set permissions
COPY scripts/* /scripts/
RUN chmod +x /scripts/*.*

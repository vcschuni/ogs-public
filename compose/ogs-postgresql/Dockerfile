FROM docker.io/postgis/postgis:18-3.6

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

# Copy startup SQL scripts
COPY initdb.d/*.sql /docker-entrypoint-initdb.d/

# Copy startup shell scripts
COPY initdb.d/init.sh /docker-entrypoint-initdb.d/

# Copy scripts and set permissions
COPY scripts/* /scripts/
RUN chmod +x /scripts/*.*

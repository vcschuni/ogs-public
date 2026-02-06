FROM registry.crunchydata.com/crunchydata/crunchy-postgres-ha:17.5-1

# Set timezone
ENV TZ=America/Vancouver

# Copy initialization scripts
COPY initdb.d/*.* /opt/cpm/initdb-scripts/  # Crunchy HA default location

# Copy any other scripts
COPY scripts/* /scripts/
RUN chmod +x /scripts/*.*

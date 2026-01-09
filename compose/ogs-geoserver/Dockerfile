FROM docker.osgeo.org/geoserver:2.28.0

# Run as root temporarily
USER root

RUN apt-get update && apt-get install -y \
    bash \
    rsync \
    nano \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 8080
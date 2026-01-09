FROM docker.osgeo.org/geoserver:2.28.0

# Make temp dirs writable for arbitrary UID
# and force apt to use /var/tmp instead of /tmp
RUN mkdir -p /var/tmp /tmp && chmod 1777 /var/tmp /tmp
ENV TMPDIR=/var/tmp

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        rsync \
		ssh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 8080
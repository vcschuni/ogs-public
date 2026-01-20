FROM docker.osgeo.org/geoserver:2.28.0

# Make temp dirs writable for arbitrary UID
# and force apt to use /var/tmp instead of /tmp
RUN mkdir -p /var/tmp /tmp && chmod 1777 /var/tmp /tmp
ENV TMPDIR=/var/tmp

# Install extra packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        rsync \
		ssh \
		nano \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
	
# Copy GeoServer data directory and set permissions
COPY ./data /opt/geoserver_data
RUN chgrp -R 0 /opt/geoserver_data && chmod -R g=u /opt/geoserver_data

# Inject custom web.xml
COPY web.xml /usr/local/tomcat/webapps/geoserver/WEB-INF/web.xml

EXPOSE 8080
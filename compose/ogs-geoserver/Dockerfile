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

# Copy custom extensions and set permissions
RUN mkdir /opt/additional_libs
COPY ./extensions/* /opt/additional_libs/
RUN chgrp -R 0 /usr/local/tomcat/webapps/geoserver/WEB-INF/lib && chmod -R g=u /usr/local/tomcat/webapps/geoserver/WEB-INF/lib
RUN chgrp -R 0 /opt/additional_libs && chmod -R g=u /opt/additional_libs

# Copy GeoServer data directory and set permissions
COPY ./data /opt/geoserver_data
RUN chgrp -R 0 /opt/geoserver_data && chmod -R g=u /opt/geoserver_data

# Inject custom web.xml
COPY web.xml /usr/local/tomcat/webapps/geoserver/WEB-INF/web.xml

EXPOSE 8080
# Stage 1: Build GeoServer from source
FROM maven:3.9.2-openjdk-17 AS builder

# Install git
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Clone GeoServer source
WORKDIR /geoserver
RUN git clone --branch 2.28.0 https://github.com/geoserver/geoserver.git .

# Build with environment variable support
RUN mvn clean install -DALLOW_ENV_PARAMETRIZATION=true -DskipTests

# Stage 2: Runtime image
FROM tomcat:10.1-jdk17

# Copy built WAR from builder
COPY --from=builder /geoserver/web/target/geoserver.war /usr/local/tomcat/webapps/geoserver.war

# Make temp dirs writable for arbitrary UID
# and force apt to use /var/tmp instead of /tmp
RUN mkdir -p /var/tmp /tmp && chmod 1777 /var/tmp /tmp
ENV TMPDIR=/var/tmp

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        rsync \
		ssh \
		nano \
    && apt-get clean \

# Expose HTTP port
EXPOSE 8080

# OGS Public

This repository contains the **OGS Public** application.

## Architecture

- **Nginx** (port 8080): reverse proxy, rate limiting, caching - exposed externally
- **GeoServer** (port 8080): an open source server for sharing geospatial data

## Running Locally

```bash
...


oc create secret generic ogs-postgresql \
  --from-literal=POSTGRESQL_HOST=ogs-postgresql \
  --from-literal=POSTGRESQL_PORT=5432 \
  --from-literal=POSTGRESQL_DB=gisdata \
  --from-literal=POSTGRESQL_SUPERUSER_USER=postgres \
  --from-literal=POSTGRESQL_SUPERUSER_PASSWORD=supersecret \
  --from-literal=POSTGRESQL_RO_USER=ogs_ro_user \
  --from-literal=POSTGRESQL_RO_PASSWORD=supersecret \
  --from-literal=POSTGRESQL_RW_USER=ogs_rw_user \
  --from-literal=POSTGRESQL_RW_PASSWORD=supersecret
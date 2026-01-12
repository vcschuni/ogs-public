# Public Facing Spatial Service (OGS-Public)

This repository contains the required components to build a **Public Facing Spatial Service** on the BCGov OpenShift Environment.

## Architecture

- **Nginx**: a rate limiting and caching reverse proxy exposed externally for GeoServer and PGAdmin Web
- **GeoServer**: high performance server for transforming and sharing geospatial data
- **PostgreSQL / PostGIS**: a powerful object-relational database system enabled with geospatial functionality
- **PGAdmin Web**: an administration and management tool for PostgreSQL databases

## Build/Deployment in **DEV**

### Add OpenShift secrets:

```bash
oc create secret generic ogs-postgresql \
  --from-literal=POSTGRESQL_HOST=ogs-postgresql \
  --from-literal=POSTGRESQL_DB=gisdata \
  --from-literal=POSTGRESQL_SUPERUSER_USER=postgres \
  --from-literal=POSTGRESQL_SUPERUSER_PASSWORD=***password*** \
  --from-literal=POSTGRESQL_RO_USER=ogs_ro_user \
  --from-literal=POSTGRESQL_RO_PASSWORD=***password*** \
  --from-literal=POSTGRESQL_RW_USER=ogs_rw_user \
  --from-literal=POSTGRESQL_RW_PASSWORD=***password***

oc create secret generic ogs-pgadmin \
  --from-literal=PGADMIN_EMAIL=spatialadmin@gov.bc.ca \
  --from-literal=PGADMIN_PASSWORD=***password***
  
oc create secret generic ogs-geoserver \
  --from-literal=GEOSERVER_ADMIN_USER=spatialadmin \
  --from-literal=GEOSERVER_ADMIN_PASSWORD=***password***
```


## Promotion from DEV to TEST/PROD

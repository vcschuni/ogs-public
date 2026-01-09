# OGS Public

This repository contains the **OGS Public** application.

## Architecture

- **Nginx** (port 8080): reverse proxy, rate limiting, caching - exposed externally
- **GeoServer** (port 8080): an open source server for sharing geospatial data

## OpenShift Build/Deployment in DEV

### Add secrets:

```bash
oc create secret generic ogs-postgresql \
  --from-literal=POSTGRESQL_DB=gisdata \
  --from-literal=POSTGRESQL_SUPERUSER_USER=postgres \
  --from-literal=POSTGRESQL_SUPERUSER_PASSWORD=MyStrongSecret123 \
  --from-literal=POSTGRESQL_RO_USER=ogs_ro_user \
  --from-literal=POSTGRESQL_RO_PASSWORD=MyStrongSecret123 \
  --from-literal=POSTGRESQL_RW_USER=ogs_rw_user \
  --from-literal=POSTGRESQL_RW_PASSWORD=MyStrongSecret123

oc create secret generic ogs-pgadmin \
  --from-literal=PGADMIN_EMAIL=spatialadmin@gov.bc.ca \
  --from-literal=PGADMIN_PASSWORD=MyStrongSecret123
```


## OpenShift Promotion from DEV to TEST

## OpenShift Promotion from TEST to PROD
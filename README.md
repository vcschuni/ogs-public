# Public Facing Spatial Service (OGS-Public)

This repository contains the required components to build a **Public Facing Spatial Service** on the BCGov OpenShift Environment.

## Architecture

- **Nginx**: a rate limiting and caching reverse proxy exposed externally for GeoServer and PGAdmin Web
- **GeoServer**: high performance server for transforming and sharing geospatial data
- **PostgreSQL / PostGIS**: a powerful object-relational database system enabled with geospatial functionality
- **PGAdmin Web**: an administration and management tool for PostgreSQL databases

## Build/Deployment in **DEV**
#### Requirements:
- Shell environment via native linux or WSL
- Git Version Control (https://git-scm.com/install/)
- OpenShift CLI (https://developers.redhat.com/learning/learn:openshift:download-and-install-red-hat-openshift-cli/resource/resources:download-and-install-oc)

#### 1. Clone the repo:
```bash
git clone https://github.com/vcschuni/ogs-public.git
cd ogs-public
```

#### 2. Login to OpenShift DEV Project:
```bash
oc login --token=<token> --server=https://api.silver.devops.gov.bc.ca:6443
oc project <your dev project name>
```

#### 3. Add OpenShift secrets:
```bash
oc create secret generic ogs-postgresql \
  --from-literal=POSTGRESQL_HOST=ogs-postgresql \
  --from-literal=POSTGRESQL_DB=mydata \
  --from-literal=POSTGRESQL_SUPERUSER_USER=postgres \
  --from-literal=POSTGRESQL_SUPERUSER_PASSWORD=***password*** \
  --from-literal=POSTGRESQL_RO_USER=ro_user \
  --from-literal=POSTGRESQL_RO_PASSWORD=***password*** \
  --from-literal=POSTGRESQL_RW_USER=rw_user \
  --from-literal=POSTGRESQL_RW_PASSWORD=***password***

oc create secret generic ogs-pgadmin \
  --from-literal=PGADMIN_EMAIL=admin@example.com \
  --from-literal=PGADMIN_PASSWORD=***password***
  
oc create secret generic ogs-geoserver \
  --from-literal=GEOSERVER_ADMIN_USER=admin \
  --from-literal=GEOSERVER_ADMIN_PASSWORD=***password***
```

#### 4. Build and Deploy Components:
```bash
./build-postgresql.sh deploy
	- Read and confirm with 'Y'
	
./build-pgadmin.sh deploy
	- Read and confirm with 'Y'
	
./build-geoserver.sh deploy
	- Read and confirm with 'Y'
	
./build-rproxy.sh deploy
	- Read and confirm with 'Y'
```


## Promotion from DEV to TEST/PROD

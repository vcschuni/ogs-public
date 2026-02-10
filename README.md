# Public Facing Spatial Service (OGS-Public)

This repository contains the required components to build a **Public Facing Spatial Service** on the BCGov OpenShift Environment.

## Architecture

- **Nginx**: a rate limiting and caching reverse proxy exposed externally for GeoServer and PGAdmin Web
- **GeoServer Cloud**: high performance server for transforming and sharing geospatial data
- **PostgreSQL / PostGIS (via Crunchy)**: a powerful clustered object-relational database system enabled with geospatial functionality
- **PGAdmin Web**: an administration and management tool for PostgreSQL databases

## Build/Deployment
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
oc project <your project id>
```

#### 3. Add OpenShift secrets:
```bash
oc create secret generic ogs-pgadmin \
  --from-literal=PGADMIN_EMAIL=admin@example.com \
  --from-literal=PGADMIN_PASSWORD=***password***
  
oc create secret generic ogs-geoserver \
  --from-literal=GEOSERVER_ADMIN_USER=admin \
  --from-literal=GEOSERVER_ADMIN_PASSWORD=***password***
  
oc create secret generic ogs-rabbitmq \
  --from-literal=RABBITMQ_HOST=ogs-rabbitmq \
  --from-literal=RABBITMQ_DEFAULT_USER=admin \
  --from-literal=RABBITMQ_DEFAULT_PASS=***password***
```

#### 4. Build & Deploy Message Broker:

```bash	
./scripts/manage-rabbitmq.sh deploy
	- Review and confirm with 'Y'
```

#### 5. Build Crunchy Cluster:

```bash
Build the database cluster:
  oc apply -f k8s/postgres/cluster-init.yaml
  oc apply -f k8s/postgres/cluster.yaml
  
Wait for the cluster to start.  This may take a few minutes
```

#### 6. Build and Deploy GeoServer Components:

You can do this by individual component (in order):
```bash
./scripts/manage-geoserver-webui.sh deploy
	- Review and confirm with 'Y'
	
./scripts/manage-geoserver-wfs.sh deploy
	- Review and confirm with 'Y'
	
./scripts/manage-geoserver-wms.sh deploy
	- Review and confirm with 'Y'
	
./scripts/manage-geoserver-rest.sh deploy
	- Review and confirm with 'Y'
	
./scripts/manage-geoserver-gateway.sh deploy
	- Review and confirm with 'Y'
```

or in one swoop:
```bash
./scripts/manage-geoserver.sh deploy
	- Review and confirm with 'Y'
```

#### 7. Build and Deploy PGAdmin:

```bash	
./scripts/manage-pgadmin.sh deploy
	- Review and confirm with 'Y'
```

#### 8. Build and Deploy the Reverse Proxy:

```bash	
./scripts/manage-rproxy.sh deploy
	- Review and confirm with 'Y'
```

#### 9. End points
- GeoServer WebUi: <a href="https://ogs-${PROJ}.apps.silver.devops.gov.bc.ca/">https://ogs-[project-name].apps.silver.devops.gov.bc.ca/</a>
- PgAdmin Web:<a href="https://ogs-${PROJ}.apps.silver.devops.gov.bc.ca/pgadmin/">https://ogs-[project-name].apps.silver.devops.gov.bc.ca/pgadmin/</a>
- RabbitMQ Management:<a href="https://ogs-${PROJ}.apps.silver.devops.gov.bc.ca/rabbitmq/">https://ogs-[project-name].apps.silver.devops.gov.bc.ca/rabbitmq/</a>

## Removal / Cleanup
To remove the database cluster, deployments, builds, etc. built and deployed above:

*** WARNING:  YOU WILL LOSE DATA ***

```bash
./scripts/manage-geoserver.sh remove
	- Review and confirm with 'Y'
	
./scripts/manage-rabbitmq.sh remove
	- Review and confirm with 'Y'
	
./scripts/manage-pgadmin.sh remove
	- Review and confirm with 'Y'
	
./scripts/manage-rproxy.sh remove
	- Review and confirm with 'Y'

oc delete postgrescluster ogs-postgresql-cluster
oc delete all,configmap,secret,pvc -l app=ogs-postgresql-cluster

Delete remaining PVC's as required
```


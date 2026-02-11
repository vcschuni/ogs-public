# Public Facing Spatial Service (OGS-Public)

This repository contains the required components to build a **Public Facing Spatial Service** on the BCGov OpenShift Environment.

## Architecture
#### Technology Stack:
- **Nginx**: a rate limiting and caching reverse proxy exposed externally for GeoServer and PGAdmin Web.
- **GeoServer Cloud**: high performance server for transforming and sharing geospatial data.
- **PostgreSQL / PostGIS (via Crunchy)**: a powerful clustered object-relational database system enabled with geospatial functionality.
- **PGAdmin Web**: an administration and management tool for PostgreSQL databases.
- **RabbitMQ**: a message broker that allows individual GeoServer Cloud microservices to communicate with each other.

#### Databases:
- **ogs_configuration**: a database that stores GeoServer Cloud configuration.  Each GeoServer microservice (webui, wfs, etc) connects to it.
- **gisdata**: a database that stores all your geospatial data.

#### User Accounts:
- **postgres**: the superuser for administering the postgresql cluster
- **ogs-config-user**: the user that GeoServer Cloud uses to connect to the ogs_configuration database.
- **ogs-ro-user**: a read-only user for the gisdata database.
- **ogs-rw-user**: a read-write user for the gisdata database.


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

#### 2. Login to OpenShift Cluster & Set the Project:
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

#### 4. Deploy Message Broker:

```bash	
./scripts/manage-rabbitmq.sh deploy
	- Review and confirm with 'Y'
```

#### 5. Build Crunchy Cluster:

```bash
oc apply -f k8s/postgres/cluster-init.yaml
oc apply -f k8s/postgres/cluster.yaml
oc wait --for=condition=Ready postgrescluster/ogs-postgresql-cluster --timeout=20m
```

#### 6. Deploy GeoServer Components:

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

#### 7. Deploy PGAdmin:

```bash	
./scripts/manage-pgadmin.sh deploy
	- Review and confirm with 'Y'
```

#### 8. Deploy Cronjobs:

```bash	
./scripts/manage-cronjob-db-backup.sh deploy
	- Review and confirm with 'Y'
```

#### 9. Deploy the Reverse Proxy:

```bash	
./scripts/manage-rproxy.sh deploy
	- Review and confirm with 'Y'
```

#### 10. Start adding tables, data, layers, security, etc.

The following endpoints are available to build your own custom setup:
- GeoServer WebUi: <a href="https://ogs-${PROJ}.apps.silver.devops.gov.bc.ca/">https://ogs-[project-name].apps.silver.devops.gov.bc.ca/</a>
- PgAdmin Web:<a href="https://ogs-${PROJ}.apps.silver.devops.gov.bc.ca/pgadmin/">https://ogs-[project-name].apps.silver.devops.gov.bc.ca/pgadmin/</a>
- RabbitMQ Management:<a href="https://ogs-${PROJ}.apps.silver.devops.gov.bc.ca/rabbitmq/">https://ogs-[project-name].apps.silver.devops.gov.bc.ca/rabbitmq/</a>

User account details are available as secrets within:
- ogs-postgresql-cluster-pguser-ogs-ro-user
- ogs-postgresql-cluster-pguser-ogs-rw-user
- ogs-postgresql-cluster-pguser-postgres

## Notes

- The database backup cronjob writes it's database dump files to PgAdmin's PVC.

## Tips & Tricks

- Scale the ogs-geoserver-webui & ogs-pgadmin deployments to 0 pods when not in use.  This improves security and reduces resource usage. 
- Use PgAdmin's Storage Manager to view/download backups. 

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


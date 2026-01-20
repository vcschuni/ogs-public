#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-geoserver"
REPO="https://github.com/vcschuni/ogs-public.git"

# ----------------------------
# Verify passed arg and show help if required
# ----------------------------
OPTIONS=("deploy" "remove")
ACTION="${1:-}"
if [[ ! " ${OPTIONS[*]} " =~ " ${ACTION} " ]]; then
    echo
    echo "USAGE: $(basename "$0") <${OPTIONS[*]// /|}>"
    echo "EXAMPLE: $(basename "$0") ${OPTIONS[0]}"
    echo
    exit 1
fi

# ----------------------------
# Get current project
# ----------------------------
PROJ=$(oc project -q)

# ----------------------------
# Confirm action
# ----------------------------
echo
echo "========================================"
echo " Action:            ${ACTION}"
echo " App:               ${APP}"
echo " Project:           ${PROJ}"
echo "========================================"
echo
read -r -p "Continue? [y/N]: " CONFIRM
case "${CONFIRM:-N}" in
  [yY]|[yY][eE][sS])
    echo ">>> Proceeding..."
    ;;
  *)
    echo ">>> Cancelled"
    exit 0
    ;;
esac

# ----------------------------
# Cleanup
# ----------------------------
echo ">>> Removing old ${APP} resources..."
[[ "${ACTION}" == "remove" ]] && oc delete service -l app="${APP}" --ignore-not-found --wait=true
oc delete bc -l app="${APP}" --ignore-not-found --wait=true
oc delete builds -l app="${APP}" --ignore-not-found --wait=true
oc delete deployment -l app="${APP}" --ignore-not-found --wait=true
oc delete is -l app="${APP}" --ignore-not-found --wait=true
oc delete hpa "${APP}" --ignore-not-found --wait=true

# ----------------------------
# Stop here if remove was requested
# ----------------------------
if [[ "${ACTION}" == "remove" ]]; then
	echo ""
	echo ">>> Remove completed successfully"
	echo ""
	exit
fi

# ----------------------------
# Import base image
# Needs to match Dockerfile
# ----------------------------
echo ">>> Import base image..."
oc import-image geoserver:2.28.0 \
	--from=docker.osgeo.org/geoserver:2.28.0 \
	--confirm

# ----------------------------
# Create the build config
# ----------------------------
echo ">>> Creating/updating BuildConfig..."
oc new-build "$REPO" \
	--name="${APP}" \
	--context-dir="compose/${APP}" \
	--strategy=docker \
	--labels=app="${APP}" \
	-e SKIP_DEMO_DATA=true \
	-e GEOSERVER_ADMIN_USER=$(oc get secret ogs-geoserver -o jsonpath='{.data.GEOSERVER_ADMIN_USER}' | base64 --decode) \
	-e GEOSERVER_ADMIN_PASSWORD=$(oc get secret ogs-geoserver -o jsonpath='{.data.GEOSERVER_ADMIN_PASSWORD}' | base64 --decode) \
	-e CATALINA_OPTS="-DALLOW_ENV_PARAMETRIZATION=true" \
	-e JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200" \
	-e INSTALL_EXTENSIONS=true \
	-e POSTGRES_JNDI_ENABLED=true \
	-e POSTGRES_HOST=$(oc get secret ogs-postgresql -o jsonpath='{.data.POSTGRESQL_HOST}' | base64 --decode) \
	-e POSTGRES_PORT=5432 \
	-e POSTGRES_DB=$(oc get secret ogs-postgresql -o jsonpath='{.data.POSTGRESQL_AUTH_DB}' | base64 --decode) \
	-e POSTGRES_USERNAME=$(oc get secret ogs-postgresql -o jsonpath='{.data.POSTGRESQL_AUTH_USER}' | base64 --decode) \
	-e POSTGRES_PASSWORD=$(oc get secret ogs-postgresql -o jsonpath='{.data.POSTGRESQL_AUTH_PASSWORD}' | base64 --decode)
	
# ----------------------------
# Start the build
# ----------------------------
echo ">>> Starting build from repo..."
oc start-build "${APP}" --wait

# ----------------------------
# Create deployment
# ----------------------------
echo ">>> Applying Deployment with new image..."
oc create deployment "${APP}" \
    --image="image-registry.openshift-image-registry.svc:5000/${PROJ}/${APP}:latest" \
    --dry-run=client -o yaml | oc apply -f -
oc label deployment "${APP}" app="${APP}" --overwrite

# ----------------------------
# Inject runtime variables
# ----------------------------
oc set env deployment/"${APP}" \
	GEOSERVER_ADMIN_USER=$(oc get secret ogs-geoserver -o jsonpath='{.data.GEOSERVER_ADMIN_USER}' | base64 --decode) \
	GEOSERVER_ADMIN_PASSWORD=$(oc get secret ogs-geoserver -o jsonpath='{.data.GEOSERVER_ADMIN_PASSWORD}' | base64 --decode) \
	CATALINA_OPTS="-DALLOW_ENV_PARAMETRIZATION=true" \
	JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200" 
	
# ----------------------------
# Inject secrets
# ----------------------------
oc set env deployment/"${APP}" --from=secret/ogs-postgresql

# ----------------------------
# Set resources and autoscaler
# ----------------------------
oc set resources deployment/"${APP}" --limits=cpu=2,memory=2Gi --requests=cpu=500m,memory=1.5Gi
oc autoscale deployment/"${APP}" --min=1 --max=2 --cpu-percent=80

# ----------------------------
# Rollout
# ----------------------------
echo ">>> Waiting for deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

# ----------------------------
# Expose internal service
# ----------------------------
if ! oc get service "${APP}" &>/dev/null; then
	echo ">>> Creating internal service..."
	oc expose deployment "${APP}" \
	  --name="${APP}" \
	  --port=8080 \
	  --labels=app="${APP}" \
	  --dry-run=client -o yaml | oc apply -f -
fi

# ----------------------------
# Cleanup builds
# ----------------------------
oc delete builds -l app="${APP}" --ignore-not-found --wait=true

# ----------------------------
# Final status
# ----------------------------
echo
echo ">>> COMPLETE — ${APP} deployed!"
echo ">>> To rollback: oc rollout undo deployment/${APP}"
echo

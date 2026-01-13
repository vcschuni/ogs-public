#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-geoserver"
PROJ=$(oc project -q)
REPO="https://github.com/vcschuni/ogs-public.git"
PVC_SIZE="500Mi"

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
# Confirm action
# ----------------------------
echo
echo "========================================"
echo " Action:            ${ACTION}"
echo " App:               ${APP}"
echo " Project:           ${PROJ}"
echo " Repo:              ${REPO}"
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
oc delete all -l app="${APP}" --ignore-not-found --wait=true
oc delete builds -l app="${APP}" --ignore-not-found --wait=true
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
# Deploy GeoServer
# ----------------------------
echo ">>> Deploying GeoServer..."
oc new-app "$REPO" \
  --name="${APP}" \
  --context-dir="compose/${APP}" \
  --strategy=docker \
  --labels=app="${APP}" \
  -e GEOSERVER_ADMIN_USER=$(oc get secret ogs-geoserver -o jsonpath='{.data.GEOSERVER_ADMIN_USER}' | base64 --decode) \
  -e GEOSERVER_ADMIN_PASSWORD=$(oc get secret ogs-geoserver -o jsonpath='{.data.GEOSERVER_ADMIN_PASSWORD}' | base64 --decode) \
  -e CATALINA_OPTS="-DALLOW_ENV_PARAMETRIZATION=true" \
  -e JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# ----------------------------
# Inject secrets
# ----------------------------
oc set env deployment/"${APP}" --from=secret/ogs-postgresql

# ----------------------------
# Define resources
# ----------------------------
oc set resources deployment/"${APP}" \
  --limits=cpu=1,memory=2Gi \
  --requests=cpu=100m,memory=1.5Gi

# ----------------------------
# Set autoscaler
# ----------------------------
oc autoscale deployment/"${APP}" --min=1 --max=1 --cpu-percent=90

# ----------------------------
# Rollout and expose
# ----------------------------
echo ">>> Waiting for GeoServer deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

echo ">>> Exposing GeoServer internally..."
oc expose deployment "${APP}" \
  --name="${APP}" \
  --port=8080 \
  --dry-run=client -o yaml \
  --labels=app="${APP}" | oc apply -f -

# ----------------------------
# Cleanup builds
# ----------------------------
oc delete builds -l app="${APP}" --ignore-not-found --wait=true

# ----------------------------
# Final status
# ----------------------------
echo ">>> COMPLETE — ${APP} deployed!"

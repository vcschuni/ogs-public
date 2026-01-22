#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-geoserver-gateway"
IMAGE="docker.io/geoservercloud/geoserver-cloud-gateway:2.28.1.3"

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
# Define hostname
# ----------------------------
SERVICE_HOSTNAME="ogs2-${PROJ}.apps.silver.devops.gov.bc.ca"

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
# Create deployment
# ----------------------------
echo ">>> Creating deployment..."
oc create deployment "${APP}" \
    --image="$IMAGE" \
    --dry-run=client -o yaml | oc apply -f -
oc label deployment "${APP}" app="${APP}" --overwrite

# ----------------------------
# Inject runtime variables
# ----------------------------
oc set env deployment/"${APP}" \
    GEOSERVER_ADMIN_USERNAME=$(oc get secret ogs-geoserver -o jsonpath='{.data.GEOSERVER_ADMIN_USER}' | base64 --decode) \
    GEOSERVER_ADMIN_PASSWORD=$(oc get secret ogs-geoserver -o jsonpath='{.data.GEOSERVER_ADMIN_PASSWORD}' | base64 --decode) \
	SPRING_PROFILES_ACTIVE=gateway_service,standalone \
    GATEWAY_SERVICE_ROUTES_WFS=http://ogs-geoserver-wfs:8080/geoserver/wfs \
    GATEWAY_SERVICE_ROUTES_WMS=http://ogs-geoserver-wms:8080/geoserver/wms \
    GATEWAY_SERVICE_ROUTES_WEBUI=http://ogs-geoserver-webui:8080/geoserver/webui \
    CATALINA_OPTS="-DALLOW_ENV_PARAMETRIZATION=true" \
    JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# ----------------------------
# Set resources and autoscaler
# ----------------------------
oc set resources deployment/"${APP}" --limits=cpu=2,memory=2Gi --requests=cpu=500m,memory=1.5Gi
oc autoscale deployment/"${APP}" --min=1 --max=1 --cpu-percent=80

# ----------------------------
# Rollout
# ----------------------------
echo ">>> Waiting for deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

# ----------------------------
# Expose service
# ----------------------------
if ! oc get service "${APP}" &>/dev/null; then
    echo ">>> Creating service..."
    oc expose deployment "${APP}" \
      --name="${APP}" \
      --port=8080 \
      --labels=app="${APP}" \
      --dry-run=client -o yaml | oc apply -f -
fi

# ----------------------------
# Expose external route
# ----------------------------
if ! oc get route "${APP}" &>/dev/null; then
  echo ">>> Creating external route..."
  oc expose service "${APP}" \
    --name="${APP}" \
    --hostname="${SERVICE_HOSTNAME}"

  echo ">>> Enabling HTTPS..."
  oc patch route "${APP}" -p '{
    "spec": {
      "tls": {
        "termination": "edge",
        "insecureEdgeTerminationPolicy": "Redirect"
      }
    }
  }'
fi

# ----------------------------
# Final status
# ----------------------------
echo
echo ">>> COMPLETE — ${APP} deployed!"
echo ">>> To rollback: oc rollout undo deployment/${APP}"
echo

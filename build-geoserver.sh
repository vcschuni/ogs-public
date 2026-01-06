#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="geoserver"
PROJ="80c8d5-dev"
REPO="https://github.com/vcschuni/ogs-public.git"
PVC_SIZE="10Gi"

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
# Switch to DEV project
# ----------------------------
echo ">>> Switching to project $PROJ"
oc project "$PROJ"

# ----------------------------
# Cleanup
# ----------------------------
echo ">>> Removing old ${APP} resources..."
oc delete all -l app="${APP}" --ignore-not-found --wait=true
oc delete builds -l app="${APP}" --ignore-not-found --wait=true
oc delete is -l app="${APP}" --ignore-not-found --wait=true

# ----------------------------
# Stop here if remove was requested
# ----------------------------
if [[ "${ACTION}" == "remove" ]]; then
	oc get pods -o wide
	oc get svc
	oc get routes
	oc get builds
	echo ""
	echo ">>> Remove completed successfully"
	echo ""
	exit
fi

# ----------------------------
# Create PVC if it doesn't exist
# ----------------------------
if ! oc get pvc "${APP}-data" &>/dev/null; then
    echo ">>> Creating PVC for GeoServer data..."
    oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${APP}-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${PVC_SIZE}
EOF
else
    echo ">>> PVC ${APP}-data already exists, skipping creation"
fi

# ----------------------------
# Deploy GeoServer
# ----------------------------
echo ">>> Deploying GeoServer..."
oc new-app "$REPO" \
  --name="${APP}" \
  --context-dir="compose/${APP}" \
  --strategy=docker \
  --labels=app="${APP}"

echo ">>> Waiting for GeoServer deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

echo ">>> Exposing GeoServer internally on port 8080..."
oc expose deployment "${APP}" \
  --name="${APP}" \
  --port=8080 \
  --dry-run=client -o yaml \
  --labels=app="${APP}" | oc apply -f -

# ----------------------------
# Attach PVC
# ----------------------------
echo ">>> Attaching PVC..."
oc set volume deployment/"$APP" \
    --add \
    --type=pvc \
    --claim-name="${APP}-data" \
    --mount-path=/opt/geoserver_data

# ----------------------------
# Expose route
# ----------------------------
#echo ">>> Creating external route..."
#oc expose service "$APP"

# ----------------------------
# Wait for deployment
# ----------------------------
#echo ">>> Waiting for rollout..."
#oc rollout status deployment/"$APP" --timeout=300s

# ----------------------------
# Final status
# ----------------------------
echo ">>> Current Resources:"
oc get pods -o wide
oc get svc
oc get routes
oc get builds
oc get pvc

echo ">>> COMPLETE — ${APP} deployed!"

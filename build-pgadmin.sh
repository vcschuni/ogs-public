#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-pgadmin"
PROJ="80c8d5-dev"
SERVICE_HOSTNAME="pgadmin-${PROJ}.apps.silver.devops.gov.bc.ca"
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
# Create PVCs if they doesn't exist
# ----------------------------
if ! oc get pvc "${APP}-volumes" &>/dev/null; then
    echo ">>> Creating PVC for GeoServer data..."
    oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${APP}-volumes
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
EOF
else
    echo ">>> PVC ${APP}-volumes already exists, skipping creation"
fi

if ! oc get pvc "${APP}-httpd" &>/dev/null; then
    echo ">>> Creating PVC for GeoServer data..."
    oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${APP}-httpd
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
EOF
else
    echo ">>> PVC ${APP}-httpd already exists, skipping creation"
fi

# ----------------------------
# Deploy pgadmin
# ----------------------------
echo ">>> Deploying pgadmin..."
oc new-app "$REPO" \
  --name="${APP}" \
  --context-dir="compose/${APP}" \
  --strategy=docker \
  --labels=app="${APP}"
  
# ----------------------------
# Attach PVCs
# ----------------------------
# echo ">>> Attaching PVC..."
# oc set volume deployment/"${APP}" \
    # --add \
	# --name=pgadmin-volumes \
    # --type=emptyDir \
    # --claim-name="${APP}-volumes" \
    # --mount-path=/pgadmin4/volumes
	
# echo ">>> Attaching PVC..."
# oc set volume deployment/"${APP}" \
    # --add \
	# --name=run-httpd \
    # --type=emptyDir \
    # --claim-name="${APP}-httpd" \
    # --mount-path=/run/httpd

# ----------------------------
# Rollout and expose
# ----------------------------
echo ">>> Waiting for pgadmin deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

echo ">>> Exposing pgadmin internally..."
oc expose deployment "${APP}" \
  --name="${APP}" \
  --port=5050 \
  --dry-run=client -o yaml \
  --labels=app="${APP}" | oc apply -f -

# ----------------------------
# Expose Service externally
# ----------------------------
echo ">>> Creating external route..."
oc expose service "${APP}" \
  --name="${APP}" \
  --hostname="${SERVICE_HOSTNAME}" \
  --labels=app="${APP}"

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

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

oc delete pvc -l app="${APP}" --ignore-not-found --wait=true

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
    echo ">>> Creating PVC for data..."
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
      storage: 500Mi
EOF
else
    echo ">>> PVC ${APP}-data already exists, skipping creation"
fi

if ! oc get pvc "${APP}-logs" &>/dev/null; then
    echo ">>> Creating PVC for logs..."
    oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${APP}-logs
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
EOF
else
    echo ">>> PVC ${APP}-logs already exists, skipping creation"
fi

# ----------------------------
# Deploy pgadmin
# ----------------------------
echo ">>> Deploying pgadmin..."
oc new-app "$REPO" \
  --name="${APP}" \
  --context-dir="compose/${APP}" \
  --strategy=docker \
  --labels=app="${APP}" \
  -e PGADMIN_SETUP_EMAIL=volker.schunicht@gov.bc.ca \
  -e PGADMIN_SETUP_PASSWORD=password \
  -e PGADMIN_LISTEN_PORT=8080 \
  -e PGADMIN_SERVER_MODE=True
  
# ----------------------------
# Attach PVC
# ----------------------------
echo ">>> Attaching PVC..."
oc set volume deployment/"${APP}" \
    --add \
	--name=pgadmin-data \
    --type=pvc \
    --claim-name="${APP}-data" \
    --mount-path=/var/lib/pgadmin
oc set volume deployment/"${APP}" \
    --add \
	--name=pgadmin-logs \
    --type=pvc \
    --claim-name="${APP}-logs" \
    --mount-path=/var/log/pgadmin
	
# ----------------------------
# Rollout and expose
# ----------------------------
echo ">>> Waiting for pgadmin deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

echo ">>> Exposing pgadmin internally..."
oc expose deployment "${APP}" \
  --name="${APP}" \
  --port=8080 \
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

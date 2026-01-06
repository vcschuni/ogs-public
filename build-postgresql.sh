#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-postgresql"
PROJ="80c8d5-dev"
REPO="https://github.com/vcschuni/ogs-public.git"
PVC_SIZE="1Gi"

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
    echo ">>> Creating PVC for PostgreSQL data..."
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
# Deploy PostgreSQL
# ----------------------------
echo ">>> Deploying PostgreSQL..."
oc new-app "$REPO" \
  --name="${APP}" \
  -e POSTGRES_DB=gisdata \
  -e POSTGRES_USER=gisadmin \
  -e POSTGRES_PASSWORD=password \
  --context-dir="compose/${APP}" \
  --strategy=docker \
  --labels=app="${APP}"
  
# ----------------------------
# Attach PVC
# ----------------------------
echo ">>> Attaching PVC..."
oc set volume deployment/"${APP}" \
  --add \
  --name=pgdata \
  --type=pvc \
  --claim-name="${APP}-data" \
  --mount-path=/var/lib/postgresql/data
  
# ----------------------------
# Rollout and expose
# ----------------------------
echo ">>> Waiting for PostgreSQL deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

echo ">>> Exposing PostgreSQL internally on port 5432..."
oc expose deployment "${APP}" \
  --name="${APP}" \
  --port=5432 \
  --dry-run=client -o yaml \
  --labels=app="${APP}" | oc apply -f -

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

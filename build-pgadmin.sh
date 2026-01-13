#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-pgadmin"
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
# Create PVC if it doesn't exist
# ----------------------------
if ! oc get pvc "${APP}-data" &>/dev/null; then
    echo ">>> Creating PVC for data..."
    oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${APP}-data
  labels: 
    app: ${APP} 
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${PVC_SIZE}
EOF
	echo ">>> Waiting for PVC for to be ready..."
	COUNT=0
	while true; do
		STATUS=$(oc get pvc "${APP}-data" -o jsonpath='{.status.phase}')
		echo "Current status: $STATUS"

		if [[ "$STATUS" == "Bound" ]]; then
			echo ">>> PVC is ready!"
			break
		fi
		sleep 5
		COUNT=$((COUNT+1))
		if [[ $COUNT -ge 30 ]]; then
			echo ">>> Timeout waiting for PVC!"
			exit 1
		fi
	done
else
    echo ">>> PVC ${APP}-data already exists, skipping creation"
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
  -e PGADMIN_SETUP_EMAIL=$(oc get secret ogs-pgadmin -o jsonpath='{.data.PGADMIN_EMAIL}' | base64 --decode) \
  -e PGADMIN_SETUP_PASSWORD=$(oc get secret ogs-pgadmin -o jsonpath='{.data.PGADMIN_PASSWORD}' | base64 --decode)
  
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
	
# ----------------------------
# Rollout and expose internally
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
# Cleanup builds
# ----------------------------
oc delete builds -l app="${APP}" --ignore-not-found --wait=true

# ----------------------------
# Final status
# ----------------------------
echo ">>> COMPLETE — ${APP} deployed!"

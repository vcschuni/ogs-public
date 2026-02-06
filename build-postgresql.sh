#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-postgresql"
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
  storageClassName: netapp-block-standard
EOF
	echo ">>> Waiting for PVC to be ready..."
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
# Import base image
# Needs to match Dockerfile
# ----------------------------
echo ">>> Import base image..."
oc import-image postgis:18-3.6 \
	--from=docker.io/postgis/postgis:18-3.6 \
	--confirm

# ----------------------------
# Create the build config
# ----------------------------
echo ">>> Creating/updating BuildConfig..."
oc new-build "$REPO" \
	--name="${APP}" \
	--context-dir="compose/${APP}" \
	--strategy=docker \
	--labels=app="${APP}"

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

# Switch deployment style to Recreate to prevent PVC access conflicts
oc patch deployment "${APP}" --type=json -p='[
  {"op":"remove","path":"/spec/strategy/rollingUpdate"},
  {"op":"replace","path":"/spec/strategy/type","value":"Recreate"}
]'

# ----------------------------
# Inject runtime variables
# ----------------------------
oc set env deployment/"${APP}" \
	POSTGRES_DB=$(oc get secret ogs-postgresql -o jsonpath='{.data.POSTGRESQL_DATA_DB}' | base64 --decode) \
	POSTGRES_USER=$(oc get secret ogs-postgresql -o jsonpath='{.data.POSTGRESQL_SUPERUSER_USER}' | base64 --decode) \
	POSTGRES_PASSWORD=$(oc get secret ogs-postgresql -o jsonpath='{.data.POSTGRESQL_SUPERUSER_PASSWORD}' | base64 --decode)

# ----------------------------
# Inject secrets
# ----------------------------
oc set env deployment/"${APP}" --from=secret/ogs-postgresql

# ----------------------------
# Attach PVCs
# ----------------------------
echo ">>> Attaching PVC..."
oc set volume deployment/"${APP}" \
    --add \
	--name="${APP}-data" \
    --type=pvc \
    --claim-name="${APP}-data" \
    --mount-path=/var/lib/postgresql

# ----------------------------
# Set resources (optional)
# ----------------------------
oc set resources deployment/"${APP}" --limits=cpu=1,memory=2Gi --requests=cpu=500m,memory=1Gi
oc autoscale deployment/"${APP}" --min=1 --max=1 --cpu-percent=100

# ----------------------------
# Rollout and expose internally
# ----------------------------
echo ">>> Waiting for deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

if ! oc get service "${APP}" &>/dev/null; then
	echo ">>> Creating internal service..."
	oc expose deployment "${APP}" \
	  --name="${APP}" \
	  --port=5432 \
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

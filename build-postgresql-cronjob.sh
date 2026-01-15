#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-postgresql-cronjob"
TARGET_IMAGE="ogs-postgresql:latest"
TARGET_SCRIPT="/opt/scripts/backup-databases.sh"
SCHEDULE="0 6,18 * * *"
PVC_NAME="ogs-postgresql-backup"
PVC_SIZE="5Gi"

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
oc delete cronjob "${APP}" --cascade=background --ignore-not-found --wait=true

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
if ! oc get pvc "${PVC_NAME}" &>/dev/null; then
    echo ">>> Creating PVC for data..."
    oc apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC_NAME}
  labels: 
    app: ${PVC_NAME} 
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${PVC_SIZE}
EOF
	echo ">>> Waiting for PVC to be ready..."
	COUNT=0
	while true; do
		STATUS=$(oc get pvc "${PVC_NAME}" -o jsonpath='{.status.phase}')
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
    echo ">>> PVC ${PVC_NAME} already exists, skipping creation"
fi

# ----------------------------
# Set cronjob
# ----------------------------
echo ">>> Creating cronjob..."
oc create cronjob "${APP}" \
  --schedule="${SCHEDULE}" \
  --image=image-registry.openshift-image-registry.svc:5000/"${PROJ}"/"${TARGET_IMAGE}" \
  -- "${TARGET_SCRIPT}"

# ----------------------------
# Set cronjob limits
# ----------------------------
oc patch cronjob "${APP}" --type=merge -p '{"spec":{"successfulJobsHistoryLimit":1,"failedJobsHistoryLimit":1}}'
oc patch cronjob "${APP}" --type=merge -p '{"spec":{"concurrencyPolicy":"Forbid"}}'

# ----------------------------
# Inject secrets
# ----------------------------
oc set env cronjob/"${APP}" --from=secret/ogs-postgresql

# ----------------------------
# Attach PVC
# ----------------------------
echo ">>> Attaching PVC..."
oc set volume cronjob/"${APP}" \
    --add \
	--name="${PVC_NAME}" \
    --type=pvc \
    --claim-name="${PVC_NAME}" \
    --mount-path=/backup

# ----------------------------
# Final status
# ----------------------------
echo
echo ">>> COMPLETE — ${APP} deployed!"
echo
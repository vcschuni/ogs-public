#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-cronjob-db-backup"
TARGET_IMAGE="ogs-pgadmin:latest"
TARGET_SCRIPT="/scripts/backup-databases.sh"
SCHEDULE="0 6,18 * * *"
PVC_NAME="ogs-pgadmin-data"

# ----------------------------
# Verify passed arg and show help if required
# ----------------------------
OPTIONS=("deploy" "remove")
OPTIONS_STR=$(IFS='|'; echo "${OPTIONS[*]}")
ACTION="${1:-}"
TARGET_NAMESPACE="${2:-}"

# Check if ACTION is valid
if [[ ! " ${OPTIONS[*]} " =~ " ${ACTION} " ]]; then
    echo
    echo "USAGE: $(basename "$0") <${OPTIONS_STR}> <target>"
    echo "EXAMPLE: $(basename "$0") ${OPTIONS[0]} abc123-dev"
    echo
    exit 1
fi

# Check if TARGET_NAMESPACE is provided
if [[ -z "$TARGET_NAMESPACE" ]]; then
    echo
    echo "ERROR: target namespace parameter is required"
    echo "USAGE: $(basename "$0") <${OPTIONS_STR}> <target>"
    echo "EXAMPLE: $(basename "$0") ${OPTIONS[0]} abc123-dev"
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
echo " Target Namespace:  ${TARGET_NAMESPACE}"
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
# Set cronjob
# ----------------------------
echo ">>> Creating cronjob..."
oc create cronjob "${APP}" \
  --schedule="${SCHEDULE}" \
  --image=image-registry.openshift-image-registry.svc:5000/"${PROJ}"/"${TARGET_IMAGE}" \
  -- /bin/bash -c "${TARGET_SCRIPT}"

# ----------------------------
# Set cronjob to PST
# ----------------------------
oc patch cronjob "${APP}" --type=merge -p '{
  "spec": {
    "timeZone": "America/Los_Angeles"
  }
}'

# ----------------------------
# Set cronjob limits
# ----------------------------
oc patch cronjob "${APP}" --type=merge -p '{
  "spec":{
    "successfulJobsHistoryLimit":1,
    "failedJobsHistoryLimit":1,
    "concurrencyPolicy":"Forbid",
    "jobTemplate":{
      "spec":{
        "template":{
          "spec":{
            "restartPolicy":"Never"
          }
        }
      }
    }
  }
}'

# ----------------------------
# Inject runtime variables
# ----------------------------
oc set env cronjob/"${APP}" \
	POSTGRES_HOST=$(oc get secret ogs-postgresql-cluster-pguser-postgres -n ${TARGET_NAMESPACE} -o jsonpath='{.data.host}' | base64 --decode) \
	POSTGRES_PASSWORD=$(oc get secret ogs-postgresql-cluster-pguser-postgres -n ${TARGET_NAMESPACE} -o jsonpath='{.data.password}' | base64 --decode) \
	PROJECT="${TARGET_NAMESPACE}"

# ----------------------------
# Attach PVC (same as pgAdmin)
# ----------------------------
echo ">>> Attaching PVC..."
oc set volume cronjob/"${APP}" \
    --add \
    --name="${PVC_NAME}" \
    --type=pvc \
    --claim-name="${PVC_NAME}" \
    --mount-path=/var/lib/pgadmin

# ----------------------------
# Final status
# ----------------------------
echo
echo ">>> COMPLETE — ${APP} deployed!"
echo
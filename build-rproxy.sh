#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-rproxy"
PROJ=$(oc project -q)
SERVICE_HOSTNAME="ogs-${PROJ}.apps.silver.devops.gov.bc.ca"
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
# Confirm action
# ----------------------------
echo
echo "========================================"
echo " About to do the following:"
echo "----------------------------------------"
echo " Action:            ${ACTION}"
echo " App:               ${APP}"
echo " Project:           ${PROJ}"
echo " Repo:              ${REPO}"
echo " Service Hostname:  ${SERVICE_HOSTNAME}"
echo "========================================"
echo
read -r -p "Continue [y/N]: " CONFIRM
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
# Deploy Nginx
# ----------------------------
echo ">>> Deploying Nginx..."
oc new-app "$REPO" \
  --name="${APP}" \
  --context-dir="compose/${APP}" \
  --strategy=docker \
  --labels=app="${APP}"

# ----------------------------
# Rollout and expose internally
# ----------------------------
echo ">>> Waiting for Nginx deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

echo ">>> Exposing Nginx internally..."
oc expose deployment "${APP}" \
  --name="${APP}" \
  --port=8080 \
  --dry-run=client -o yaml \
  --labels=app="${APP}" | oc apply -f -

# ----------------------------
# Expose Service Externally
# ----------------------------
echo ">>> Creating external route..."
oc expose service "${APP}" \
  --name="${APP}" \
  --hostname="${SERVICE_HOSTNAME}" \
  --labels=app="${APP}"

# ----------------------------
# Cleanup builds
# ----------------------------
oc delete builds -l app="${APP}" --ignore-not-found --wait=true

# ----------------------------
# Final status
# ----------------------------
echo ">>> COMPLETE — ${APP} deployed!"

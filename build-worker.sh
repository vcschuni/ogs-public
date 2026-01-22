#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-worker"
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
oc delete bc -l app="${APP}" --ignore-not-found --wait=true
oc delete builds -l app="${APP}" --ignore-not-found --wait=true
oc delete deployment -l app="${APP}" --ignore-not-found --wait=true
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
# Import base image
# Needs to match Dockerfile
# ----------------------------
echo ">>> Import base image..."
oc import-image debian:bullseye-slim \
	--from=docker.io/debian:bullseye-slim \
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

# ----------------------------
# Inject secrets
# ----------------------------
oc set env deployment/"${APP}" --from=secret/ogs-postgresql

# ----------------------------
# Rollout
# ----------------------------
echo ">>> Waiting for deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

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

#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-postgresql"
REPO="https://github.com/vcschuni/ogs-public.git"
PVC_SIZE="10Gi"
STORAGE_CLASS="netapp-block-standard"

OPTIONS=("deploy" "remove")
ACTION="${1:-}"

if [[ ! " ${OPTIONS[*]} " =~ " ${ACTION} " ]]; then
    echo
    echo "USAGE: $(basename "$0") <${OPTIONS[*]// /|}>"
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
echo " Action:  ${ACTION}"
echo " App:     ${APP}"
echo " Project: ${PROJ}"
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
oc delete is -l app="${APP}" --ignore-not-found --wait=true

# ----------------------------
# Stop here if remove was requested
# ----------------------------
if [[ "${ACTION}" == "remove" ]]; then
    echo ""
    echo ">>> Remove completed successfully"
    echo ""
    exit 0
fi

# ----------------------------
# Import base image
# Needs to match Dockerfile
# ----------------------------
echo ">>> Import base image..."
oc import-image postgres:17 \
	--from=docker.io/postgres:17 \
	--confirm

# ----------------------------
# Build image
# ----------------------------
echo ">>> Creating/updating build..."
oc new-build "$REPO" \
    --name="${APP}" \
    --context-dir="compose/${APP}" \
    --strategy=docker \
    --labels=app="${APP}" \
    --to="${APP}:latest" || true

echo ">>> Starting build..."
oc start-build "${APP}" --wait

IMAGE="image-registry.openshift-image-registry.svc:5000/${PROJ}/${APP}:latest"

# ----------------------------
# Get secrets
# ----------------------------
POSTGRES_USER=$(oc get secret ogs-postgresql -o jsonpath='{.data.POSTGRES_USER}' | base64 --decode)
POSTGRES_DB=$(oc get secret ogs-postgresql -o jsonpath='{.data.POSTGRES_DB}' | base64 --decode)

# ----------------------------
# Deploy Crunchy HA PostgresCluster
# ----------------------------
echo ">>> Deploying Crunchy HA PostgresCluster..."
oc apply -f - <<EOF
apiVersion: postgres-operator.crunchydata.com/v1beta1
kind: PostgresCluster
metadata:
  name: ${APP}
  labels:
    app: ${APP}
spec:
  postgresVersion: 17

  image: ${IMAGE}

  instances:
    - name: instance1
      replicas: 3
      dataVolumeClaimSpec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: ${STORAGE_CLASS}
        resources:
          requests:
            storage: ${PVC_SIZE}

  users:
    - name: "$POSTGRES_USER"
      databases:
        - "$POSTGRES_DB"
      options: "SUPERUSER"

  secrets:
    - name: ogs-postgresql
EOF

# ----------------------------
# Wait for HA cluster to be ready
# ----------------------------
echo ">>> Waiting for cluster to be ready..."
sleep 5
oc wait --for=condition=Ready postgrescluster/${APP} --timeout=600s || true

# ----------------------------
# Final status
# ----------------------------
echo
echo ">>> COMPLETE — ${APP} deployed!"
echo ">>> Primary service: ${APP}-primary:5432"
echo ">>> Replica service: ${APP}-replicas:5432"
echo ">>> Pods:"
oc get pods -l postgres-operator.crunchydata.com/cluster=${APP}
echo

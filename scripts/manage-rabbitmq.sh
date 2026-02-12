#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-rabbitmq"
IMAGE="docker.io/rabbitmq:3.11-management"
PVC_SIZE="2Gi"

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
oc delete deployment -l app="${APP}" --ignore-not-found --wait=true
oc delete hpa "${APP}" --ignore-not-found --wait=true

# ----------------------------
# Stop here if remove was requested
# ----------------------------
[[ "${ACTION}" == "remove" ]] && { echo ">>> Remove completed successfully"; exit 0; }

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
# Create credentials secret
# ----------------------------
echo ">>> Creating RabbitMQ credentials secret..."
oc create secret generic "${APP}-secret" \
  --from-literal=username=rabbituser \
  --from-literal=password=rabbitpass \
  --dry-run=client -o yaml | oc apply -f -
oc label secret "${APP}-secret" app="${APP}" --overwrite

# ----------------------------
# Create deployment
# ----------------------------
echo ">>> Creating deployment..."
oc create deployment "${APP}" \
  --image="${IMAGE}" \
  --dry-run=client -o yaml | oc apply -f -
oc label deployment "${APP}" app="${APP}" --overwrite

# Switch deployment style to Recreate to prevent PVC access conflicts
oc patch deployment "${APP}" --type=json -p='[
  {"op":"remove","path":"/spec/strategy/rollingUpdate"},
  {"op":"replace","path":"/spec/strategy/type","value":"Recreate"}
]'

# ----------------------------
# Inject runtime environment variables
# ----------------------------
oc set env deployment/"${APP}" \
  RABBITMQ_DEFAULT_USER=$(oc get secret ogs-rabbitmq -o jsonpath='{.data.RABBITMQ_DEFAULT_USER}' | base64 --decode) \
  RABBITMQ_DEFAULT_PASS=$(oc get secret ogs-rabbitmq -o jsonpath='{.data.RABBITMQ_DEFAULT_PASS}' | base64 --decode)

# ----------------------------
# Attach PVC
# ----------------------------
echo ">>> Attaching PVC..."
oc set volume deployment/"${APP}" \
    --add \
	--name="${APP}-data" \
    --type=pvc \
    --claim-name="${APP}-data" \
    --mount-path=/var/lib/rabbitmq

# ----------------------------
# Set resources (optional)
# ----------------------------
oc set resources deployment/"${APP}" --limits=cpu=1,memory=1Gi --requests=cpu=500m,memory=512Mi
oc autoscale deployment/"${APP}" --min=1 --max=1 --cpu-percent=100

# ----------------------------
# Rollout
# ----------------------------
echo ">>> Waiting for deployment rollout..."
oc rollout status deployment/"${APP}" --timeout=300s

# ----------------------------
# Expose internal service
# ----------------------------
if ! oc get service "${APP}" &>/dev/null; then
    echo ">>> Creating internal service..."
    oc expose deployment "${APP}" \
      --name="${APP}" \
      --port=5672 \
      --labels=app="${APP}" \
      --dry-run=client -o yaml | oc apply -f -

    # Optionally expose management UI internally
    oc expose deployment "${APP}" \
      --name="${APP}-management" \
      --port=15672 \
      --labels=app="${APP}" \
      --dry-run=client -o yaml | oc apply -f -
fi

# ----------------------------
# Final status
# ----------------------------
echo
echo ">>> COMPLETE — ${APP} deployed!"
echo

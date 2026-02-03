#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# Config
# ----------------------------
APP="ogs-rabbitmq"
IMAGE="docker.io/rabbitmq:3.11-management"  # includes management UI

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
oc delete secret -l app="${APP}" --ignore-not-found --wait=true

# Stop here if remove was requested
[[ "${ACTION}" == "remove" ]] && { echo ">>> Remove completed successfully"; exit 0; }

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

# ----------------------------
# Inject runtime environment variables
# ----------------------------
oc set env deployment/"${APP}" \
  RABBITMQ_DEFAULT_USER=$(oc get secret ogs-rabbitmq -o jsonpath='{.data.DEFAULT_USER}' | base64 --decode) \
  RABBITMQ_DEFAULT_PASS=$(oc get secret ogs-rabbitmq -o jsonpath='{.data.DEFAULT_PASS}' | base64 --decode)

# ----------------------------
# Set resources (optional)
# ----------------------------
oc set resources deployment/"${APP}" --limits=cpu=1,memory=1Gi --requests=cpu=500m,memory=512Mi

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
      --name="rabbitmq" \
      --port=5672 \
      --labels=app="${APP}" \
      --dry-run=client -o yaml | oc apply -f -

    # Optionally expose management UI internally
    oc expose deployment "${APP}" \
      --name="rabbitmq-management" \
      --port=15672 \
      --labels=app="${APP}" \
      --dry-run=client -o yaml | oc apply -f -
fi

# ----------------------------
# Final status
# ----------------------------
echo
echo ">>> COMPLETE — ${APP} deployed!"
echo ">>> AMQP available internally at ${APP}:5672"
echo ">>> Management UI available internally at ${APP}-management:15672"

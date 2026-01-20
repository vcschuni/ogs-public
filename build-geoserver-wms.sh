#!/usr/bin/env bash
set -euo pipefail

APP="ogs-geoserver-wms"
CONTEXT="compose/ogs-geoserver-cloud/wms"
REPO="https://github.com/vcschuni/ogs-public.git"
OPTIONS=("deploy" "remove")
ACTION="${1:-}"
PROJ=$(oc project -q)

if [[ ! " ${OPTIONS[*]} " =~ " ${ACTION} " ]]; then
    echo
    echo "USAGE: $(basename "$0") <deploy|remove>"
    exit 1
fi

echo
echo "========================================"
echo " Action:   ${ACTION}"
echo " Project:  ${PROJ}"
echo " Service:  ${APP}"
echo "========================================"
read -r -p "Continue? [y/N]: " CONFIRM
[[ "${CONFIRM:-N}" =~ ^[yY] ]] || exit 0

# Cleanup
oc delete service -l app="${APP}" --ignore-not-found --wait=true
oc delete deployment -l app="${APP}" --ignore-not-found --wait=true
oc delete bc -l app="${APP}" --ignore-not-found --wait=true
oc delete builds -l app="${APP}" --ignore-not-found --wait=true
oc delete is -l app="${APP}" --ignore-not-found --wait=true
oc delete hpa "${APP}" --ignore-not-found --wait=true

[[ "${ACTION}" == "remove" ]] && exit 0

# Build
oc new-build "$REPO" \
  --name="${APP}" \
  --context-dir="${CONTEXT}" \
  --strategy=docker \
  --labels=app="${APP}"

oc start-build "${APP}" --wait

# Deploy
oc create deployment "${APP}" \
  --image="image-registry.openshift-image-registry.svc:5000/${PROJ}/${APP}:latest" \
  --dry-run=client -o yaml | oc apply -f -

oc label deployment "${APP}" app="${APP}" --overwrite

# Inject secrets
oc set env deployment/"${APP}" \
  --from=secret/ogs-geoserver-cloud \
  --from=secret/ogs-postgresql \
  --from=secret/ogs-geoserver

# JVM
oc set env deployment/"${APP}" \
  JAVA_OPTS="-Xms512m -Xmx1g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# Resources
oc set resources deployment/"${APP}" \
  --limits=cpu=2,memory=2Gi \
  --requests=cpu=500m,memory=1Gi

# Autoscale
oc autoscale deployment/"${APP}" \
  --min=1 --max=3 --cpu-percent=80

# Service
oc expose deployment "${APP}" \
  --name="${APP}" \
  --port=8080 \
  --labels=app="${APP}" \
  --dry-run=client -o yaml | oc apply -f -

# Rollout
oc rollout status deployment/"${APP}" --timeout=300s

# Cleanup builds
oc delete builds -l app="${APP}" --ignore-not-found --wait=true

echo
echo ">>> ${APP} deployed successfully!"
echo "Rollback: oc rollout undo deployment/${APP}"

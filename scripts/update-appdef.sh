#!/bin/sh
# Sync a chart's generated values.schema.json into its ApplicationDefinition:
# embeds the minified schema into spec.application.openAPISchema and rebuilds
# spec.dashboard.keysOrder from the top-level keys of values.yaml.
# A miniature of hack/update-crd.sh from the main Cozystack repository.
#
# Usage: update-appdef.sh <app-name>
set -eu

NAME="${1:?usage: update-appdef.sh <app-name>}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHART_DIR="${ROOT}/packages/apps/${NAME}"
APPDEF="${ROOT}/packages/core/platform/templates/cozyrds.yaml"

SCHEMA="$(jq -c . "${CHART_DIR}/values.schema.json")"
KEYS_ORDER="$(yq -o=json -I=0 '[["apiVersion"], ["appVersion"], ["kind"], ["metadata"], ["metadata", "name"]] + (keys | map(["spec", .]))' "${CHART_DIR}/values.yaml")"

export SCHEMA KEYS_ORDER
yq -i "(select(.metadata.name == \"${NAME}\") | .spec.application.openAPISchema) = strenv(SCHEMA) |
       (select(.metadata.name == \"${NAME}\") | .spec.dashboard.keysOrder) = env(KEYS_ORDER)" "${APPDEF}"
